
class Updates

  def self.all_repo_diffs(settings)
    settings.properties['repositories'].collect do |repo|
      { repo['name'] => diff_dirs(repo['path'], settings.accepted_dir(repo['name'])) }
    end
  end

  # either source_dir or accepted_dir is assumed to exist
  # subpath is assumed to be in one of them
  #
  # return an array of all different paths underneath either dir, like 'diff --brief'
  # return an array of:
  # { 'path' => path,
  #   'source' => T|F in source tree,
  #   'accepted' => T|F in accepted tree,
  #   'ftype' => see File.ftype, including 'unknown' (such as when types don't match)
  # }
  def self.diff_dirs(source_dir, accepted_dir, subpath = "")
    source_file = File.join(source_dir, subpath)
    accepted_file = File.join(accepted_dir, subpath)
    if (! File.exist? source_file)
      [{'path' => subpath, 'source' => false, 'accepted' => true, 'ftype' => File.ftype(accepted_file) }]
    elsif (! File.exist? accepted_file)
      [{'path' => subpath, 'source' => true, 'accepted' => false, 'ftype' => File.ftype(source_file) }]
    elsif (File.file?(source_file) && File.file?(accepted_file))
      if (File.mtime(source_file) != File.mtime(accepted_file))
        [{'path' => subpath, 'source' => true, 'accepted' => true, 'ftype' => 'file' }]
      elsif (File.size(source_file) != File.size(accepted_file))
        [{'path' => subpath, 'source' => true, 'accepted' => true, 'ftype' => 'file' }]
      end
    elsif (File.directory?(source_file) && File.directory?(accepted_file))
      diff_subs = Dir.entries(source_file) | Dir.entries(accepted_file)
      diff_subs.reject! { |sub| sub == '.' || sub == '..' }
      diff_subs.map! { |entry| diff_dirs(source_dir, accepted_dir, File.join(subpath, entry)) }
      diff_subs.flatten.compact
    else
      [{'path' => subpath, 'source' => true, 'accepted' => true, 'ftype' => 'unknown' }]
    end
  end

end
