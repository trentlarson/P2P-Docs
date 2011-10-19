# make different combinations of versioned files

require 'fileutils'

class SampleReposVersioned
  
  def self.create(app_sources_base_dir, test_content_dir, app_dir)
    
    if (app_sources_base_dir.class.name == "RubyKObject")
      app_sources_base_dir = app_sources_base_dir.toString()
    end
    if (test_content_dir.class.name == "RubyKObject")
      test_content_dir = test_content_dir.toString()
    end
    if (app_dir.class.name == "RubyKObject")
      app_dir = app_dir.toString()
    end
    
    require File.join(app_sources_base_dir, "ruby/settings.rb")
    require File.join(app_sources_base_dir, "ruby/updates.rb")
    require File.join(app_sources_base_dir, "test/ruby/test_utils.rb")
    
    app_file = File.expand_path(File.join(app_dir, "application.properties"))
    base_repo_dir = File.expand_path(File.join(test_content_dir, "sample-repos-versioned"))
    FileUtils.rm_rf(base_repo_dir)
    settings = Settings.new(base_repo_dir)
    
    # change the app properties file such that settings come from the correct place 
    if (not File.exist?(app_file))
      puts "I have to modify the Titanium app properties, but I can't find the file."
      exit 1
    end
    app_props = YAML.load_file(app_file)
    if (app_props['settings-dir'] != settings.data_dir())
      if (app_props['settings-dir'] != nil)
        # back up the current settings
        app_props['//settings-dir'] = app_props['settings-dir']
      end
      app_props['settings-dir'] = settings.data_dir()
      File.open(app_file, 'w') do |out|
        YAML.dump(app_props, out)
      end
    end
    
    repo_name = "test 0"
    repo_dir_name = File.join(base_repo_dir, settings.fixed_repo_name(repo_name))
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
      
      File.open(File.join(repo_dir_name, "test_4.txt"), 'w') do |out|
        out.write("data\n")
        out.write("... is in your future, buddy.\n")
      end
    end

    repo_name = "test 1 - should see no changes to accept"
    repo_dir_name = File.join(base_repo_dir, settings.fixed_repo_name(repo_name))
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
      
      Updates.mark_reviewed(settings, repo_name, "test_2.txt")
      
    end

  end

end

#SampleReposVersioned.create(File.join(File.expand_path(File.dirname(__FILE__)), "../.."), "build")