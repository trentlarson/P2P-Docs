require 'fileutils'

# command-line usage:
# 1) Uncomment the last line(s) of this file, then:
# ruby updates.rb
# 2) ... or do this:
# ruby -e 'load "updates.rb"; SEE_END_OF_FILE'


rver = RUBY_VERSION.split(".")
if (rver[0].to_i + ("." + rver[1]).to_f < 1.9)
  # add the == method for comparing my test results in 1.8
  class MatchData
    def ==(b)
      return b != nil &&
        pre_match == b.pre_match &&
        to_a == b.to_a &&
        post_match == b.post_match
    end
  end
end
  
class Updates
  
  # takes an argument which is any nesting of String, Array, and Hash objects (and nil)
  # return a string holding JSON representation of the argument
  def self.strings_arrays_hashes_json(arg)
    if (arg == nil)
      "null"
    elsif (arg.class.name == "String")
      result = arg
      result = result.gsub("\"","\\\"")
      result = result.gsub("\\","\\\\")
      result = result.gsub("\/","\\/")
      result = result.gsub("\b","\\b")
      result = result.gsub("\f","\\f")
      result = result.gsub("\n","\\n")
      result = result.gsub("\r","\\r")
      result = result.gsub("\t","\\t")
      "\"" + result + "\""
    elsif (arg.class.name == "Array")
      recurse = arg.map { |elem| strings_arrays_hashes_json elem }
      "[" + recurse.join(", ") + "]"
    elsif (arg.class.name == "Hash")
      hashes = arg.to_a.map { |key, val| "\"#{key}\":#{strings_arrays_hashes_json(val)}" }
      "{" + hashes.join(", ") + "}"
    end
  end
  
  # return the diffs of the incoming files and reviewed files;
  # format is an array of { 'name' => REPO_NAME, 'diffs' => RESULT_OF_DIFF_DIRS }
  def self.all_repo_diffs(settings)
    result = settings.properties['repositories']
    if (result == nil) 
      []
    else
      result = 
        result.collect do |repo|
        { 'name' => repo['name'], 
          'diffs' => versioned_diffs(repo['incoming_loc'], settings.reviewed_dir(repo['name']))
        }
      end
      result.select { |hash| hash['diffs'] != [] }
    end
  end
  
  # return the diffs of my copies of files and outgoing files;
  # format is an array of { 'name' => REPO_NAME, 'diffs' => RESULT_OF_DIFF_DIRS }
  def self.all_outgoing_diffs(settings)
    result = settings.properties['repositories']
    if (result == nil) 
      []
    else
      result = 
        result.collect do |repo|
        { 'name' => repo['name'],
          'diffs' => versioned_diffs_out(repo['my_loc'], repo['outgoing_loc'])
        }
      end
      result.select { |hash| hash['diffs'] != [] }
    end
  end
  
  
  
  # diff is one element from diff_dirs
  # return an array of either a) the full initial file name or b) the base name, the extension or "", and the version (this should be a Class of it's own)
  def self.version_of(diff)
    match = match_of_versioned_file(diff)
    match == nil ? [diff['path']] : [match[1], match[4].to_s, match[3].to_i]
  end
  
  # version is a version array (see versioned_filenames)
  # return initial file name
  def self.version_initial(version)
    version[0] + version.at(1).to_s
  end
  
  
  
  
  # versioned_info is an array of hash: 'version' is a version and 'diff_match' is a hash where 'diff' is one element from diff_dirs
  # latest_target_versions is the result from latest_versions
  # incoming is true if we're doing the incoming directory, false otherwise
  # return results of diff_dirs augmented with:
  # {
  #   'target_path_previous_version' => the name of the previously reviewed version of this file (for setups with versions that come in via different file names)
  #   'target_path_next_version' => the name of the next version of the target file (for setups where outgoing files are incremented)
  # }
  # ... but without the entries where source version is gone (ie. source_type==nil) if a newer version exists
  def self.versioned_diffs(source_dir, target_dir)
    versioned_diffs2(diff_dirs(source_dir, target_dir), target_dir)
  end
  def self.versioned_diffs2(diff_dirs_result, target_dir)
    versioned_info = versioned_filenames(diff_dirs_result)
    versions = versioned_info.map { |v_dm| v_dm['version'] }
    
    latest_target_versions = latest_versions(versions, target_dir)

    # now output the files with the latest target versions

    versioned_info.map { |v_dm|
      version = v_dm['version']
      diff = v_dm['diff_match']['diff']
      diff_version_num = version.length == 1 ? -1 : version[2]
      latest_target_version = latest_target_versions[version_initial(version)]
      latest_target_version_num = latest_target_version == nil ? -1 : 
        latest_target_version.length == 1 ? -1 : latest_target_version[2]
      if (diff_version_num < latest_target_version_num &&
          # cases:
          # - both are 'file' (so files differ): who cares, since it's old
          # - it's nil (gone) in source: let's not remove it, and leave that up this user's settings
          # - it's nil (gone) in target: that's OK, no need to copy the old version 
          (diff['source_type'] == nil || diff['source_type'] == 'file') &&
          (diff['target_type'] == nil || diff['target_type'] == 'file'))
        nil
      else
        latest_target = latest_target_version == nil ? nil :
          latest_target_version.length == 1 ? latest_target_version[0] :
          latest_target_version[0] + "_" + latest_target_version[2].to_s + latest_target_version[1]
        max_version = [diff_version_num, latest_target_version_num].max.to_s
        next_target = latest_target_version == nil ? diff['path'] :
          latest_target_version.length == 1 ? latest_target_version[0] :
          latest_target_version[0] + "_" + max_version + latest_target_version[1]
        {
          'path' => diff['path'],
          'source_type' => diff['source_type'],
          'target_type' => diff['target_type'],
          'target_path_previous_version' => latest_target,
          'target_path_next_version' => next_target,
          'contents' => diff['contents']
        }
      end
    }.compact
  end
  
  # see versioned_diffs
  def self.versioned_diffs_out(source_dir, target_dir)
    versioned_diffs_out2(diff_dirs(source_dir, target_dir), source_dir, target_dir)
  end
  def self.versioned_diffs_out2(diff_dirs_result, source_dir, target_dir)
    versioned_info = diff_dirs_result.map { |diff|
      {'version'=>version_of(diff), 'diff_match'=>{'diff'=>diff}}
    }
    # gather all the paths, except those which are versioned, put them in the version format
    versions = diff_dirs_result.map { |diff|
      (!match_numeric_suffix(diff['path'])) ? version_of(diff) : nil
    }.compact
    # now remove any diffs only in the target... we'll just ignore them (possibly with some cleanup process later)
    versioned_info.delete_if { |v_dm| 
      #match_numeric_suffix(v_dm['diff_match']['diff']['path']) != nil &&
      #versions.include?([version_initial(v_dm['version'])]) &&
      v_dm['diff_match']['diff']['source_type'] == nil
    }

    latest_target_versions = latest_versions(versions, target_dir)

    # now output the files with incremented target versions

    versioned_info.map { |v_dm|
      version = v_dm['version']
      diff = v_dm['diff_match']['diff']
      latest_target_version = latest_target_versions[version_initial(version)]
      latest_target_version_num = latest_target_version == nil ? -1 : 
        latest_target_version.length == 1 ? -1 : latest_target_version[2]
      # this is where we'll add the different outgoing setup (without versions)
      latest_target = latest_target_version == nil ? nil :
        latest_target_version.length == 1 ? latest_target_version[0] :
        latest_target_version[0] + "_" + latest_target_version[2].to_s + latest_target_version[1]
      source_already_copied = true
      if (latest_target != nil &&
          diff['source_type'] == 'file' &&
          # if the size and modified time are the same, we'll assume it's already copied
          File.size(File.join(source_dir, diff['path'])) == File.size(File.join(target_dir, latest_target)) &&
          File.mtime(File.join(source_dir, diff['path'])) <= File.mtime(File.join(target_dir, latest_target)))
         nil
      else
        max_version = (latest_target_version_num + 1).to_s
        if (latest_target_version == nil ||
            latest_target_version.length == 1) 
          possible_splits = possible_version_exts(version_initial(version))
          if (possible_splits == nil)
            base = version_initial(version)
            ext = ""
          else
            base = possible_splits.last[0]
            ext = possible_splits.last[1]
          end
        else
          base = latest_target_version[0]
          ext = latest_target_version[1]
        end
        next_target = base + "_" + max_version + ext
        {
          'path' => diff['path'],
          'source_type' => diff['source_type'],
          'target_type' => diff['target_type'],
          'target_path_previous_version' => latest_target,
          'target_path_next_version' => next_target,
          'contents' => diff['contents']
        }
      end
    }.compact
  end
  
  # deprecated
  def self.only_new_revisions(versioned_info, versions, target_dir, incoming)
    
    latest_target_versions = latest_versions(versions, target_dir)

    versioned_info.map { |v_dm|
      version = v_dm['version']
      diff = v_dm['diff_match']['diff']
      diff_version_num = version.length == 1 ? -1 : version[2]
      latest_target_version = latest_target_versions[version_initial(version)]
      latest_target_version_num = latest_target_version == nil ? -1 : 
        latest_target_version.length == 1 ? -1 : latest_target_version[2]
      # this is where we'll add the different outgoing setup (without versions)
      if (incoming &&
          diff_version_num < latest_target_version_num &&
          # cases:
          # - both are 'file' (so files differ): who cares, since it's old
          # - it's nil (gone) in source: let's not remove it, and leave that up this user's settings
          # - it's nil (gone) in target: that's OK, no need to copy the old version 
          (diff['source_type'] == nil || diff['source_type'] == 'file') &&
          (diff['target_type'] == nil || diff['target_type'] == 'file'))
        nil
      else
        latest_target = latest_target_version == nil ? nil :
          latest_target_version.length == 1 ? latest_target_version[0] :
          latest_target_version[0] + "_" + latest_target_version[2].to_s + latest_target_version[1]
        if (incoming)
          max_version = [diff_version_num, latest_target_version_num].max.to_s
          next_target = latest_target_version == nil ? nil :
            latest_target_version.length == 1 ? latest_target_version[0] :
            latest_target_version[0] + "_" + max_version + latest_target_version[1]
        else
          max_version = (latest_target_version_num + 1).to_s
          if (latest_target_version == nil ||
              latest_target_version.length == 1) 
            possible_splits = possible_version_exts(version_initial(version))
            if (possible_splits == nil)
              base = version_initial(version)
              ext = ""
            else
              base = possible_splits.last[0]
              ext = possible_splits.last[1]
            end
          else
            base = latest_target_version[0]
            ext = latest_target_version[1]
          end
          next_target = base + "_" + max_version + ext
        end
        {
          'path' => diff['path'],
          'source_type' => diff['source_type'],
          'target_type' => diff['target_type'],
          'target_path_previous_version' => latest_target,
          'target_path_next_version' => next_target,
          'contents' => diff['contents']
        }
      end
    }.compact
  end
  
  # using the version info, look into the target directory and grab the most recent version of each
  # versions is some array of hashes each containing a 'version' key
  # return hash of from initial file name to the last version (array triple) in the target_dir (may be nil)
  def self.latest_versions(versions, target_dir)
    
    bases_exts = versions.map { |vers|
      [vers[0], vers.at(1).to_s]
    }.uniq
    non_versioned_bases = versions.map { |vers| 
      vers.length == 1 ? vers[0] : nil
    }.compact
    possible_versions = non_versioned_bases.map { |initial_file|
      possible_version_exts(initial_file)
    }.flatten(1).compact
    any_bases_exts = bases_exts + possible_versions
    
    # get matching files in the target directory, and group by initial filename
    initial_with_max_version_at_target = {}
    any_bases_exts.each { |base, ext|
      more_versions = all_target_file_versions(target_dir, base, ext)
      max_already = initial_with_max_version_at_target[base + ext]
      if (max_already != nil)
        more_versions << max_already
      end
      new_maxes = more_versions.sort_by { |version|
        if (version.length == 1)
          [version[0], -1]
        else
          [version[0] + version[1], version[2]]
        end 
      }
      initial_with_max_version_at_target[base + ext] = new_maxes.last
    }
    initial_with_max_version_at_target
  end
  
  # return array of base-ext pairs for each possible cut position for versioning, or nil if there are no candidate positions
  def self.possible_version_exts(path)
    path_file = File.split(path)
    segments = path_file[1].split(".")
    # add the '.' back to each but the first
    if (segments.length == 1)
      nil
    else
      dot_segs = [segments[0]] + (segments[1..segments.length].map{|seg| "." + seg})
      result = []
      for i in 0 .. dot_segs.length-2
        prefix = dot_segs.first(i+1).join
        if (path_file[0] != ".")
          prefix = File.join(path_file[0], dot_segs.first(i+1).join)
        end
        result << [prefix, dot_segs.last(dot_segs.length-i-1).join]
      end
      result
    end
  end
  
  # base is the base name of the file
  # ext is the file extension, which is optional if you're just looking for the existence of the initial file
  # return an array of:
  # - the initial file of [dir+base+ext], if it exists,
  # - plus all files that match_numeric_suffix, as [dir+base, ext, version]
  def self.all_target_file_versions(dir, base, extension = nil)
    
    ext = extension.to_s
    initial_file_array = Dir.glob(File.join(dir, base + ext)).empty? ? [] : [[base + ext]]
    
    more_files = ext.nil? ? [] : Dir.glob(File.join(dir, base + "_*" + ext))
    more_matches = more_files.map { |name| match_numeric_suffix(name) }.compact
    more_arrays = more_matches.map { |m| [File.split(m[1])[1], m[4].to_s, m[3].to_i] }
    
    initial_file_array + more_arrays
  end
  
  
  
  # diff_dirs_result is the output from diff_dirs
  # return an array of hashes of:
  # 'version' => see version_of
  # 'diff_match' => a hash of { 'diff' => result of one diff_dirs element, 'match' of MatchData results for versioned names }
  def self.versioned_filenames(diff_dirs_result)
    diff_matches = diff_dirs_result.map { |diff| {"diff"=>diff, "match"=>match_of_versioned_file(diff)} }
    diffs_grouped = diff_matches.group_by { |diff_match| m = diff_match["match"]; m == nil ? nil : [m[1], m[4].to_s] }
    diffs_grouped.map { |base_ext, diff_matches|
      diff_matches.map { |diff_match| {'version'=>version_of(diff_match['diff']), 'diff_match'=>diff_match} }
    }.flatten(1).sort_by { |version_diff_match|
      # because we want the basic file to come before the others
      version = version_diff_match['version']
      if (version.length == 1)
        [version[0], -1]
      else
        [version[0] + version[1], version[2]]
      end 
    }
  end
  
  # diff is an element in the result of diff_dirs
  # return MatchData of match_numeric_suffix if the 'path' types are file or nil, otherwise nil
  def self.match_of_versioned_file(diff)
    if ((diff['source_type'] == nil || diff['source_type'] == 'file') &&
        (diff['target_type'] == nil || diff['target_type'] == 'file'))
      return match_numeric_suffix(diff['path'])
    else
      return nil
    end
  end

  # This detects a suffix of "_" + a number, after the file name and before the file extension(s).
  # filename is any file name (possibly include a path prefix)
  # returns the MatchData (or nil) of matching the pattern, where:
  #  [0] = full text
  #  [1] = prefix / basic file name
  #  [2] = "_"
  #  [3] = numeric suffix
  #  [4] = "." + extension(s), which may be nil since it's optional
  def self.match_numeric_suffix(filename)
    /^(.+)(_)([0-9]+)(\..*)?$/.match(filename)
  end
  
  # subpath is assumed to be in either source_dir or target_dir
  #
  # return an array of all different paths below dirs, like the Unix 'diff --brief'
  # return an array of:
  # { 'path' => path, being the name of the file or directory (never nil, but may be an empty string),
  #   'source_type' => 'file', 'directory', or ftype if exists in source dir tree (otherwise nil),
  #   'target_type' => 'file', 'directory', or ftype if exists in reviewed dir tree (otherwise nil),
  #   'contents' => the recursive list of non-directories if a directory that only exists in one (otherwise nil)
  # }
  def self.diff_dirs(source_dir, target_dir, subpath = "")
    
    if ((source_dir.nil? || source_dir.empty?) ||
        (target_dir.nil? || target_dir.empty?))
      # we shouldn't even be here in this case, but we'll play nice
      return []
    end
    
    if (subpath == "")
      source_file = source_dir
      target_file = target_dir
    else
      source_file = File.join(source_dir, subpath)
      target_file = File.join(target_dir, subpath)
    end
    
    if (!File.exist?(source_file) && !File.exist?(target_file))
      # we shouldn't even be here in this case, but we'll play nice
      []
    elsif (! File.exist? target_file) # but source_file must exist
      if (FileTest.directory? source_file)
        contents = all_files_below(source_file, "")
        if (!contents.empty?)
          [{'path' => subpath, 'source_type' => 'directory', 'target_type' => nil, 'contents' => contents}]
        else
          []
        end
      else
        [{'path' => subpath, 'source_type' => File.ftype(source_file), 'target_type' => nil, "contents" => nil }]
      end
    elsif (! File.exist? source_file) # but target_file must exist
      if (FileTest.directory? target_file)
        contents = all_files_below(target_file, "")
        if (!contents.empty?)
          [{'path' => subpath, 'source_type' => nil, 'target_type' => 'directory', 'contents' => contents}]
        else
          []
        end
      else
        [{'path' => subpath, 'source_type' => nil, 'target_type' => File.ftype(target_file), "contents" => nil }]
      end
      
    # both source_file and target_file exist
    elsif (File.file?(source_file) && File.file?(target_file))
      if (File.size(source_file) != File.size(target_file))
        [{'path' => subpath, 'source_type' => 'file', 'target_type' => 'file', "contents" => nil }]
      elsif (File.mtime(source_file) > File.mtime(target_file))
        [{'path' => subpath, 'source_type' => 'file', 'target_type' => 'file', "contents" => nil }]
      else
        []
      end
    elsif (File.directory?(source_file) && File.directory?(target_file))
      diff_subs = Dir.entries(source_file) | Dir.entries(target_file)
      diff_subs.reject! { |sub| sub == '.' || sub == '..' }
      diff_subs.map! { |entry| diff_dirs(source_dir, target_dir, subpath == "" ? entry : File.join(subpath, entry)) }
      diff_subs.flatten.compact
    elsif (File.ftype(source_file) != File.ftype(target_file))
      if (File.directory?(source_file))
          [{'path' => subpath, 'source_type' => 'directory', 'target_type' => File.ftype(target_file),
             'contents' => all_files_below(source_file, "")}]
      elsif (File.directory?(target_file))
          [{'path' => subpath, 'source_type' => File.ftype(source_file), 'target_type' => 'directory',
             'contents' => all_files_below(target_file, "")}]
      else
        [{'path' => subpath, 'source_type' => File.ftype(source_file), 'target_type' => File.ftype(target_file), "contents" => nil }]
      end
    else
      []
    end
  end

  # takes the name of a file or directory
  # return array of same thing if a file, or all the files underneath if a directory
  def self.all_files_below(source_dir, subpath)
    if (subpath.start_with? "/")
      # this is just to solve where the first recursive call joins "" and the file
      subpath = subpath[1, subpath.length - 1]
    end
    full_dir = File.join(source_dir, subpath)
    #puts "  recursing... #{full_dir} a file? #{FileTest.file? full_dir} #{File.ftype(full_dir)}"
    if (FileTest.file? full_dir)
      #puts "  recurse ended on file #{full_dir}: #{[full_dir]}"
      [subpath]
    elsif (FileTest.directory? full_dir)
      entries = Dir.entries(full_dir).reject{ |entry| entry == '.' || entry == '..' }
      #puts "  recursing on #{entries}: #{entries.map{ |entry| all_files_below(source_dir, File.join(subpath, entry)) }.flatten}"
      entries.map{ |entry| all_files_below(source_dir, File.join(subpath, entry)) }.flatten
    else
      # it's an unknown ftype; we'll ignore it
      []
    end
  end

  # marks the subpath in repo['incoming_loc'] as reviewed
  # remove is the previous file, and it will be removed
  def self.mark_reviewed(settings, repo_name, subpath = nil, remove = nil)
    repo = settings.get_repo_by_name(repo_name)
    copy_all_contents(repo['incoming_loc'], settings.reviewed_dir(repo), subpath)
    if (remove != nil)
      FileUtils::remove_entry_secure(File.join(settings.reviewed_dir(repo), remove), true)
    end
  end


  # copies the subpath in repo['my_loc'] to outgoing
  def self.copy_to_outgoing(settings, repo_name, source_subpath = nil, target_subpath = nil)
    repo = settings.get_repo_by_name(repo_name)
    copy_all_contents(repo['my_loc'], repo['outgoing_loc'], source_subpath, target_subpath)
    if (repo['outgoing_loc'] == repo['incoming_loc'])
      copy_all_contents(repo['outgoing_loc'], settings.reviewed_dir(repo), target_subpath, target_subpath)
    end
  end


  # copy everything from the source to the target, under a common subpath
  # subpath may be nil
  def self.copy_all_contents(source_loc, target_loc, source_subpath = nil, target_subpath = nil)
    if (source_subpath.nil?)
      source = source_loc
      target = target_loc
    else
      source = File.join(source_loc, source_subpath)
      if (target_subpath.nil?)
        target = File.join(target_loc, source_subpath)
      else
        target = File.join(target_loc, target_subpath)
      end
    end
    FileUtils::remove_entry_secure(target, true)
    if (FileTest.exist? source)
      FileUtils::mkpath(File.dirname(target))
      FileUtils::cp_r(source, target, :preserve => true)
    end
  end
  
end

#puts Updates.all_repo_diffs(Settings.new("build/test-data")).to_s
