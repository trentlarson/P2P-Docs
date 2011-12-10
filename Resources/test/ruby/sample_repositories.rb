# make many repositories (setup, not real tests)

require 'fileutils'

class SampleManyRepos

  # app_sources_base_dir holds our app files (under Resources)
  # test_content_dir is where we'll put the test data
  # app_dir is where the application properties are located
  def self.create(app_sources_base_dir, test_content_dir)

    if (app_sources_base_dir.class.name == "RubyKObject")
      app_sources_base_dir = app_sources_base_dir.toString()
    end
    if (test_content_dir.class.name == "RubyKObject")
      test_content_dir = test_content_dir.toString()
    end
    
    require File.join(app_sources_base_dir, "ruby/settings.rb")
    require File.join(app_sources_base_dir, "test/ruby/test_utils.rb")

    FileUtils.rm_rf(test_content_dir)
    settings = Settings.new(test_content_dir, Settings::BLANK_SETTINGS)

    # make a bunch of repositories
    (0..100).each do |num|
      repo_name = "test #{num}"
      repo_dir_name = File.join(test_content_dir, settings.fixed_repo_name(repo_name))
      TestUtils.add_repo(settings, repo_name, repo_dir_name)
      File.open(File.join(repo_dir_name, "test.txt"), 'w') do |out|
        out.write("data\n")
      end
    end

  end
end


