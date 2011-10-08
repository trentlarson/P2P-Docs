require "fileutils"

class TestUtils
  
  # settings is Settings object
  # other things are strings for file paths
  def self.add_repo(settings, name, incoming_loc, my_loc = nil, outgoing_loc = nil, not_versioned = false)
    repo = settings.add_repo(name, incoming_loc, my_loc, outgoing_loc, not_versioned)
    if (repo != nil)
      make_repo_dirs(repo)
      settings.save()
    end
    repo
  end
  
  def self.make_repo_dirs(repo)
    if (repo['incoming_loc'] != nil)
      FileUtils::remove_entry_secure(repo['incoming_loc'], true)
      FileUtils.mkdir_p(repo['incoming_loc'])
    end
    if (repo['my_loc'] != nil)
      FileUtils::remove_entry_secure(repo['my_loc'], true)
      FileUtils.mkdir_p(repo['my_loc'])
    end
    if (repo['outgoing_loc'] != nil)
      FileUtils::remove_entry_secure(repo['outgoing_loc'], true)
      FileUtils.mkdir_p(repo['outgoing_loc'])
    end
  end
  
end
