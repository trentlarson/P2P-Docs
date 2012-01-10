# make different combinations of versioned files (setup, not real tests)

require 'fileutils'

class SampleReposVersioned
  
  def self.create(app_sources_base_dir, test_content_dir)
    
    if (app_sources_base_dir.class.name == "RubyKObject")
      app_sources_base_dir = app_sources_base_dir.toString()
    end
    if (test_content_dir.class.name == "RubyKObject")
      test_content_dir = test_content_dir.toString()
    end
    
    require File.join(app_sources_base_dir, "ruby/settings.rb")
    require File.join(app_sources_base_dir, "ruby/updates.rb")
    require File.join(app_sources_base_dir, "test/ruby/test_utils.rb")
    
    FileUtils.rm_rf(test_content_dir)
    settings = Settings.new(test_content_dir, Settings::BLANK_SETTINGS)

    repo_name = "test 0"
    repo_dir_name = File.join(test_content_dir, settings.fixed_repo_name(repo_name))
    added = TestUtils.add_repo(settings, repo_name, repo_dir_name)
    if (!added)
      raise "I was unable to create the #{repo_name} repository.  This happens if you've already set up this test, and I don't know why."
    else
      File.open(File.join(repo_dir_name, "test.txt"), 'w') do |out|
        out.write("data\n")
      end
      
      File.open(File.join(repo_dir_name, "test_2.txt"), 'w') do |out|
        out.write("data\n")
        out.write("... is in your future\n")
      end
      
      File.open(File.join(repo_dir_name, "test_4.txt"), 'w') do |out|
        out.write("data\n")
        out.write("... is in your future, buddy.\n")
      end
    end

    repo_name = "test 1 - should see no changes to accept"
    repo_dir_name = File.join(test_content_dir, settings.fixed_repo_name(repo_name))
    added = TestUtils.add_repo(settings, repo_name, repo_dir_name)
    if (!added)
      raise "I was unable to create the #{repo_name} repository."
    else
      File.open(File.join(repo_dir_name, "test.txt"), 'w') do |out|
        out.write("data\n")
      end
      
      File.open(File.join(repo_dir_name, "test_2.txt"), 'w') do |out|
        out.write("data\n")
        out.write("... is in your future\n")
      end
      
      Updates.mark_reviewed(settings, added['id'], "test_2.txt")
      
    end


    repo_name = "test 2 - should see changes, including a difference"
    repo_dir_name = File.join(test_content_dir, settings.fixed_repo_name(repo_name))
    added = TestUtils.add_repo(settings, repo_name, repo_dir_name)
    if (!added)
      raise "I was unable to create the #{repo_name} repository."
    else
      File.open(File.join(repo_dir_name, "test.html"), 'w') do |out|
        out.write("<html><body>\n")
        out.write("Shopping List\n")
        out.write("<ul>\n")
        out.write("  <li>bananas</li>\n")
        out.write("  <li>bread</li>\n")
        out.write("  <li>milk</li>\n")
        out.write("</ul>\n")
        out.write("</body></html>\n")
      end
      Updates.mark_reviewed(settings, added['id'], 'test.html')
      
      File.open(File.join(repo_dir_name, "test.html"), 'w') do |out|
        out.write("<html><body>\n")
        out.write("Shopping List\n")
        out.write("<ul>\n")
        out.write("  <li>apples</li>\n")
        out.write("  <li>bread</li>\n")
        out.write("  <li>cookies</li>\n")
        out.write("  <li>milk</li>\n")
        out.write("</ul>\n")
        out.write("</body></html>\n")
      end
    end
    
  end

end

#SampleReposVersioned.create(File.join(File.expand_path(File.dirname(__FILE__)), "../.."), "build")
