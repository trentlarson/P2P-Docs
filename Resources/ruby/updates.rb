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
  
  # subpath is assumed to be in one of them
  #
  # return an array of all different paths below dirs, like 'diff --brief'
  # return an array of:
  # { 'path' => path, being the name of the file or directory (never nil, but may be an empty string),
  #   'source_type' => 'file', 'directory', or ftype if exists in source dir tree (otherwise nil),
  #   'target_type' => 'file', 'directory', or ftype if exists in reviewed dir tree (otherwise nil),
  #   'contents' => for directories that only exist in one, the recursive list of non-directories (otherwise nil)
  # }
  def self.diff_dirs(source_dir, target_dir, subpath = "")
    
    if (subpath == "")
      source_file = source_dir
      target_file = target_dir
    else
      source_file = File.join(source_dir, subpath)
      target_file = File.join(target_dir, subpath)
    end
    
    if (source_file.nil? || target_file.nil?)
      # we shouldn't even be here in this case, but we'll play nice
      []
    elsif (!File.exist?(source_file) && !File.exist?(target_file))
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

  # marks the subpath in repo as reviewed
  def self.mark_reviewed(settings, repo_name, subpath = nil)
    repo = settings.get_repo_by_name(repo_name)
    copy_all_contents(repo['incoming_loc'], settings.reviewed_dir(repo), subpath)
  end

  # marks the subpath in repo as reviewed
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
    if (FileTest.exist? source)
      FileUtils::mkpath(File.dirname(target))
      FileUtils::remove_entry_secure(target, true)
      FileUtils::cp_r(source, target, :preserve => true)
    else
      FileUtils.remove_entry_secure(target, true)
    end
  end
  
end

#puts Updates.all_repo_diffs(Settings.new("build/test-data")).to_s
