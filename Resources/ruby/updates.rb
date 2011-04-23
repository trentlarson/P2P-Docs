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
  # return an array of all different paths underneath either dir, like 'diff --brief'
  # return an array of:
  # { 'path' => path,
  #   'source' => T|F in source tree,
  #   'reviewed' => T|F in reviewed tree,
  #   'ftype' => see File.ftype, including 'unknown' (such as when types don't match)
  # }
  def self.diff_dirs(source_dir, reviewed_dir, subpath = "")
    if (subpath.start_with? "/")
      subpath = subpath[1, subpath.length - 1]
    end
    source_file = File.join(source_dir, subpath)
    reviewed_file = File.join(reviewed_dir, subpath)
    if (! File.exist? source_file)
      [{'path' => subpath, 'source' => false, 'reviewed' => true, 'ftype' => File.ftype(reviewed_file) }]
    elsif (! File.exist? reviewed_file)
      [{'path' => subpath, 'source' => true, 'reviewed' => false, 'ftype' => File.ftype(source_file) }]
    elsif (File.file?(source_file) && File.file?(reviewed_file))
      if (File.size(source_file) != File.size(reviewed_file))
        [{'path' => subpath, 'source' => true, 'reviewed' => true, 'ftype' => 'file' }]
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

  def self.mark_reviewed(settings, repo, subpath)
    source = File.join(repo['source_dir'], subpath)
    if (FileTest.exist? source)
      if (FileTest.file? source)
          FileUtils::cp(File.join(repo['source_dir'], subpath),
                        File.join(settings.reviewed_dir(repo['name']), subpath))
      else
        # handle where it's a directory
      end
    else
      # gotta handle where it's deleted from source
    end
  end

end
