require 'fileutils'

# command-line usage:
# 1) Uncomment the last line(s) of this file, then:
# ruby updates.rb
# 2) ... or do this:
# ruby -e 'load "updates.rb"; SEE_END_OF_FILE'

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
          'diffs' => versioned_diffs(diff_dirs(repo['incoming_loc'], 
                                               settings.reviewed_dir(repo['name'])),
                                     settings.reviewed_dir(repo['name']))
        }
      end
      junk = result.select { |hash| hash['diffs'] != [] }
#puts "My whole diff: " + junk.inspect
      junk
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
        { 'name' => repo['name'], 'diffs' => diff_dirs(repo['my_loc'], repo['outgoing_loc']) }
      end
      result.select { |hash| hash['diffs'] != [] }
    end
  end
  
  # return results of diff_dirs augmented with:
  # {
  #   'target_path_previous_version' => the name of the previously reviewed version of this file (for setups with versions that come in via different file names)
  # }
  # ... but without the entries where source version is gone (ie. source_type==nil) if a new version exists
  def self.versioned_diffs(diff_dirs_result, target_dir)
    versioned_info = versioned_filenames(diff_dirs_result)
    latest_target_versions = latest_versions(versioned_info, target_dir)
    
    versioned_info.map { |v_dm|
      version = v_dm['version']
      diff = v_dm['diff_match']['diff']
      diff_version_num = version.length == 1 ? -1 : version[2]
      latest_target_version = latest_target_versions[initial]
      target_version_num = latest_target_version == nil ? -1 : 
        latest_target_version.length == 1 ? -1 : latest_target_version[2]
      if (diff_version_num < target_version_num &&
          diff['source_type'] == 'file' &&
          diff['target_type'] == 'file')
        nil
      else
        latest_target = latest_target_version == nil ? nil :
          latest_target_version.length == 1 ? latest_target_version[0] :
          latest_target_version[0] + "_" + latest_target_version[2] + latest_target_version[1]
        {
          'path' => diff['path'],
          'source_type' => diff['source_type'],
          'target_type' => diff['target_type'],
          'target_path_previous_version' => latest_target,
          'contents' => diff['contents']
        }
      end
    }.compact
  end
  
  # using the versioned_filenames, look into the target directory and grab the most recent version of each
  # return hash of 'initial' with initial file name and 'last_version' of the last version in the target_dir
  def self.latest_versions(versioned_filenames_result, target_dir)
    
    bases_exts = versioned_filenames_result.map { |v_dm| 
      vers = v_dm['version']; 
      [vers[0], vers.length==1 ? "" : vers[1]] 
    }.uniq
    
    # get matching files in the target directory, and group by initial filename
    initial_with_all_versions_at_target = bases_exts.map { |base, ext|
      [base + ext, all_target_file_versions(target_dir, base, ext)]
    }.group_by { |base_ext, file_versions| base_ext }
    
    # now combine all those with the same initial filename
    result = Hash.new
    initial_with_all_versions_at_target.map { |base_ext, base_ext_versions_list|
      result[base_ext] = base_ext_versions_list.map { |base_ext, versions| versions }.flatten(1).uniq.sort.last
    }
    result
    
=begin This worked when we put the reviewed file into the base version.  (When saving versions, we have to look on the file system.)  It's probably obsolete now.
    # remove all the ones where the source version is gone and there's a later version
    all_base_paths = all_bases_and_versions.keys
    result.delete_if { |result_info|
      # check that the source is gone
      result_info['source_type'] == nil &&
      result_info['target_type'] == 'file' &&
      # ... where our reviewed target is our the base version
      all_base_paths.include?(result_info['target_path']) &&
      # ... and there's at least one new version (besides the base version)
      all_bases_and_versions[result_info['target_path']].length >= 2
    }
=end
  end
  
  # base is the base name of the file
  # ext is the file extension, which can be "" or optional if you're just looking for the existence of the initial file
  # return an array of:
  # the initial file of [dir+base+ext], if it exists,
  # plus all files that match_numeric_suffix, as [dir+base, ext, version]
  def self.all_target_file_versions(dir, base, ext = "")
    
    initial_file_array = Dir.glob(File.join(dir, base + ext)).empty? ? [] : [[File.join(dir, base + ext)]]
    
    more_files = ext.nil? ? [] : Dir.glob(File.join(dir, base + "_*" + ext))
    more_matches = more_files.map { |name| match_numeric_suffix(name) }.compact
    more_arrays = more_matches.map { |m| [m[1], m[4], m[3].to_i] }
    
    initial_file_array + more_arrays
  end
  
  
  
  def self.filter_for_versions_above(base, version_diff_matches, all_target_files)
    version_diff_matches.map { |elem| elem['diff_match'] }
  end
  
  
  
  # diff_dirs_result is the output from diff_dirs
  # return a hash of:
  # 'version' => an array of either a) the full initial file name or b) the base name, the extension, and the version
  # 'diff_match' => a hash of { 'diff' => result of diff_dirs, 'match' of MatchData results for versioned names }
  def self.versioned_filenames(diff_dirs_result)
    diff_matches = diff_dirs_result.map { |diff| {"diff"=>diff, "match"=>match_of_versioned_file(diff)} }
    diffs_grouped = diff_matches.group_by { |diff_match| m = diff_match["match"]; m == nil ? nil : [m[1], m[4]] }
    diffs_grouped.map { |base_ext, diff_matches|
      if (base_ext.nil?)
        # these have no version suffixes
        diff_matches.collect { |diff_match| {'version'=>[diff_match['diff']['path']], 'diff_match'=>diff_match} }
      else
        diff_matches.collect { |diff_match| {'version'=>[base_ext[0], base_ext[1], diff_match['match'][3].to_i], 'diff_match'=>diff_match} }
      end
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

  def self.match_of_versioned_file(diff)
    if ((diff['source_type'] != nil && diff['source_type'] != 'file') ||
        (diff['target_type'] != nil && diff['target_type'] != 'file'))
      return nil
    else
      return match_numeric_suffix(diff['path'])
    end
  end

  # This detects a suffix of "_" + a number, after the file name and before the file extension(s).
  # filename is any file name (possibly include a path prefix)
  # returns the MatchData (or nil) of matching the pattern, where:
  #  [0] = full text
  #  [1] = prefix / basic file name
  #  [2] = "_"
  #  [3] = numeric suffix
  #  [4] = "." + extension(s)
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
  def self.mark_reviewed(settings, repo_name, subpath = nil)
    repo = settings.get_repo_by_name(repo_name)
    copy_all_contents(repo['incoming_loc'], settings.reviewed_dir(repo), subpath)
  end


  # copies the subpath in repo['my_loc'] to outgoing
  def self.copy_to_outgoing(settings, repo_name, subpath = nil)
    repo = settings.get_repo_by_name(repo_name)
    copy_all_contents(repo['my_loc'], repo['outgoing_loc'], subpath)
  end


  # copy everything from the source to the target, under a common subpath
  # subpath may be nil
  def self.copy_all_contents(source_loc, target_loc, subpath = nil)
    if (subpath.nil?)
      source = source_loc
      target = target_loc
    else
      source = File.join(source_loc, subpath)
      target = File.join(target_loc, subpath)
    end
    FileUtils::remove_entry_secure(target, true)
    if (FileTest.exist? source)
      FileUtils::mkpath(File.dirname(target))
      FileUtils::cp_r(source, target, :preserve => true)
    end
  end
  
end

#puts Updates.all_repo_diffs(Settings.new("build/test-data")).to_s
