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
  
  # return an array of { 'name' => REPO_NAME, 'diffs' => RESULT_OF_DIFF_DIRS }
  def self.all_repo_diffs(settings)
    result = settings.properties['repositories']
    if (result == nil) 
      []
    else
      result = 
        result.collect do |repo|
        { 'name' => repo['name'], 'diffs' => diff_dirs(repo['source_dir'], settings.reviewed_dir(repo['name'])) }
      end
      junk = result.select { |hash| hash['diffs'] != [] }
#puts "My whole diff: " + junk.inspect
      junk
    end
  end
  
  # subpath is assumed to be in one of them
  #
  # return an array of all different paths below dirs, like 'diff --brief'
  # return an array of:
  # { 'path' => path, being the name of the file or directory (never nil, but may be an empty string),
  #   'source' => 'file', 'directory', or ftype if exists in source dir tree (otherwise nil),
  #   'reviewed' => 'file', 'directory', or ftype if exists in reviewed dir tree (otherwise nil),
  #   'contents' => for directories that only exist in one, the recursive list of non-directories (otherwise nil)
  # }
  def self.diff_dirs(source_dir, reviewed_dir, subpath = "")
    source_file = File.join(source_dir, subpath)
    reviewed_file = File.join(reviewed_dir, subpath)
    if (!File.exist?(source_file) && !File.exist?(reviewed_file))
      # we shouldn't even be here in this case, but we'll play nice
      []
    elsif (! File.exist? reviewed_file)
      if (FileTest.directory? source_file)
        contents = all_files_below(source_file, "")
        if (!contents.empty?)
          [{'path' => subpath, 'source' => 'directory', 'reviewed' => nil, 'contents' => contents}]
        else
          []
        end
      else
        [{'path' => subpath, 'source' => File.ftype(source_file), 'reviewed' => nil, "contents" => nil }]
      end
    elsif (! File.exist? source_file)
      if (FileTest.directory? reviewed_file)
        contents = all_files_below(reviewed_file, "")
        if (!contents.empty?)
          [{'path' => subpath, 'source' => nil, 'reviewed' => 'directory', 'contents' => contents}]
        else
          []
        end
      else
        [{'path' => subpath, 'source' => nil, 'reviewed' => File.ftype(reviewed_file), "contents" => nil }]
      end
    elsif (File.file?(source_file) && File.file?(reviewed_file))
      if (File.size(source_file) != File.size(reviewed_file))
        [{'path' => subpath, 'source' => 'file', 'reviewed' => 'file', "contents" => nil }]
      else
        []
      end
    elsif (File.directory?(source_file) && File.directory?(reviewed_file))
      diff_subs = Dir.entries(source_file) | Dir.entries(reviewed_file)
      diff_subs.reject! { |sub| sub == '.' || sub == '..' }
      diff_subs.map! { |entry| diff_dirs(source_dir, reviewed_dir, subpath == "" ? entry : File.join(subpath, entry)) }
      diff_subs.flatten.compact
    elsif (File.ftype(source_file) != File.ftype(reviewed_file))
      if (File.directory?(source_file))
          [{'path' => subpath, 'source' => 'directory', 'reviewed' => File.ftype(reviewed_file),
             'contents' => all_files_below(source_file, "")}]
      elsif (File.directory?(reviewed_file))
          [{'path' => subpath, 'source' => File.ftype(source_file), 'reviewed' => 'directory',
             'contents' => all_files_below(reviewed_file, "")}]
      else
        [{'path' => subpath, 'source' => File.ftype(source_file), 'reviewed' => File.ftype(reviewed_file), "contents" => nil }]
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
  def self.mark_reviewed(settings, repo_name, subpath)
    repo = settings.get_repo(repo_name)
    source = File.join(repo['source_dir'], subpath)
    target = File.join(settings.reviewed_dir(repo), subpath)
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
