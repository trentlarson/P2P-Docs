require 'fileutils'

class Updates

  def self.all_repo_diffs(settings)
    result = settings.properties['repositories']
    if (result == nil) 
      []
    else
      result = 
        settings.properties['repositories'].collect do |repo|
        { repo['name'] => diff_dirs(repo['source_dir'], settings.reviewed_dir(repo['name'])) }
      end
      result.select { |hash| hash.values.flatten != [] }
    end
  end

  # either source_dir or reviewed_dir is assumed to exist
  # subpath is assumed to be in one of them
  #
  # return an array of all different paths below dirs, like 'diff --brief'
  # return an array of:
  # { 'path' => path,
  #   'source' => T/F whether in source tree,
  #   'reviewed' => T/F whether in reviewed tree,
  #   'ftype' => see File.ftype, including 'unknown' (such as when types don't match)
  #   'contents' => for directories that only exist in one, the recursive list of files
  # }
  def self.diff_dirs(source_dir, reviewed_dir, subpath = "")
    if (subpath.start_with? "/")
      # this is just to solve where the first recursive call joins "" and the file
      subpath = subpath[1, subpath.length - 1]
    end
    source_file = File.join(source_dir, subpath)
    reviewed_file = File.join(reviewed_dir, subpath)
#puts "trying source " + source_file
#puts "trying reviewed " + reviewed_file
    if (! File.exist? source_file)
      if (FileTest.file? reviewed_file)
        [{'path' => subpath, 'source' => false, 'reviewed' => true, 'ftype' => "file" }]
      elsif (FileTest.directory? reviewed_file)
        contents = all_files_below(reviewed_file, "")
        if (!contents.empty?)
          [{'path' => subpath, 'source' => false, 'reviewed' => true, 'ftype' => "directory",
             'contents' => contents}]
        else
          []
        end
      else
        []
      end
    elsif (! File.exist? reviewed_file)
      if (FileTest.file? source_file)
        [{'path' => subpath, 'source' => true, 'reviewed' => false, 'ftype' => "file" }]
      elsif (FileTest.directory? source_file)
        contents = all_files_below(source_file, "")
#puts "contents below " + source_file + ": " + contents.inspect
        if (!contents.empty?)
          [{'path' => subpath, 'source' => true, 'reviewed' => false, 'ftype' => "directory",
             'contents' => contents}]
        else
          []
        end
      else
        []
      end
    elsif (File.file?(source_file) && File.file?(reviewed_file))
      if (File.size(source_file) != File.size(reviewed_file))
        [{'path' => subpath, 'source' => true, 'reviewed' => true, 'ftype' => 'file' }]
      else
        []
      end
    elsif (File.directory?(source_file) && File.directory?(reviewed_file))
      diff_subs = Dir.entries(source_file) | Dir.entries(reviewed_file)
      diff_subs.reject! { |sub| sub == '.' || sub == '..' }
      diff_subs.map! { |entry| diff_dirs(source_dir, reviewed_dir, File.join(subpath, entry)) }
      diff_subs.flatten.compact
    else
      [{'path' => subpath, 'source' => true, 'reviewed' => true, 'ftype' => 'unknown' }]
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
#puts "  recursing on #{entries}: #{entries.map{ |entry| all_files_below(entry) }.flatten}"
      entries.map{ |entry| all_files_below(source_dir, File.join(subpath, entry)) }.flatten
    else
      # it's an unknown ftype; we'll ignore it
      []
    end
  end

  # marks the subpath in repo as reviewed
  def self.mark_reviewed(settings, repo, subpath)
    # Implementation note: I'm not invoking this method recursively (though I
    # realize I'm using recursive copy, which is different).  I suggest we keep
    # it that way because the user is specifically acting on the given path.
    # It makes a difference in the case where some element is no longer in the
    # source but is still in the reviewed path; we currently leave it for the
    # user to explicitly review and remove, but if we recursed we would get to
    # that element and always decide it must be removed.

    source = File.join(repo['source_dir'], subpath)
    target = File.join(settings.reviewed_dir(repo), subpath)
    if (FileTest.exist? source)
      if (FileTest.file? source)
        FileUtils::mkpath(File.dirname(target))
        FileUtils::cp(source, target, :preserve => true)
      elsif (FileTest.directory? source)
        if (File.exist? target)
          FileUtils::cp_r(source + '/.', target, :preserve => true)
        else
          FileUtils::mkpath(File.dirname(target))
          FileUtils::cp_r(source, target, :preserve => true)
        end
      else
        # it's an unknown ftype; we'll ignore it
      end
    else
      FileUtils.rm_rf(target, :secure => true)
    end
  end

end
