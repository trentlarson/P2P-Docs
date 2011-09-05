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
        { 'name' => repo['name'], 'diffs' => diff_dirs(repo['incoming_loc'], settings.reviewed_dir(repo['name'])) }
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
  #   'previous_version' => the name of the previously reviewed version (for setups with versions that come in via different file names)
  # }
  def self.versioned_diffs(settings, diff_dirs_result)
  end
  
  # diff_dirs_result is the output from diff_dirs
  # return a list of array-pairs: the element from diff_dirs, followed by the MatchData results for paths that have a versioned suffix or nil for paths without
  def self.versioned_filenames(diff_dirs_result)
    diff_dirs_result.collect { |diff| [diff, match_numeric_suffix(diff['path'])] }
  end

=begin
  # This approach isn't currently used.
  # diff_dirs_result is the output from diff_dirs
  # return a list of MatchData results for any paths that have a versioned suffix
  def self.versioned_filenames_old(diff_dirs_result)
    # gather all paths
    paths = diff_dirs_result.map{ |diff| diff['path'] }.sort
    # group them by their path base file name
    paths_wo_version = paths.group_by { |path| m = match_numeric_suffix(path); m == nil ? nil : "#{m[1]}#{m[4]}" }
    # for each that may be versioned, search for a previous version
    paths_wo_version.collect { |key, value|
      if (key.nil?)
        # it has no version suffixes
        nil
      else
         # (yes, I match them all a second time... I should fix the group_by to use MatchData... so go ahead and sue me)
        if (value.length == 1)
          match_numeric_suffix(value[0])
        else
          # grab the one with the highest version number
          value.collect{|file| m = match_numeric_suffix(file); [m[3].to_i, m]}.sort.last[1]
        end
      end
    }.reject { |x| x.nil? }
  end
=end  
  
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
