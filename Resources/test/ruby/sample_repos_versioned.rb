# make different combinations of versioned files

require 'fileutils'
require File.join(File.expand_path(File.dirname(__FILE__)), "../../ruby/settings.rb")
require File.join(File.expand_path(File.dirname(__FILE__)), "test_utils.rb")

base_repo_dir = File.expand_path(File.join("build", "sample-repos-versioned"))
FileUtils.rm_rf(base_repo_dir)
settings = Settings.new(base_repo_dir)

# change the app properties file such that settings come from the correct place 
app_file = File.expand_path("~/Library/Application Support/Titanium/appdata/info.familyhistories.p2pdocs12/application.properties")
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
TestUtils.add_repo(settings, repo_name, repo_dir_name)

File.open(File.join(repo_dir_name, "test.txt"), 'w') do |out|
  out.write("data\n")
end

File.open(File.join(repo_dir_name, "test_2.txt"), 'w') do |out|
  out.write("data\n")
  out.write("... is in your future\n")
end

