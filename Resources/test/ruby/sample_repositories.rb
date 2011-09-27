require 'fileutils'
require File.join(File.expand_path(File.dirname(__FILE__)), "../../ruby/settings.rb")

base_repo_dir = File.expand_path(File.join("build", "sample-repos"))
FileUtils.rm_rf(base_repo_dir)
settings = Settings.new(base_repo_dir)

# make a bunch of repositories
(0..50).each do |num|
  repo_name = "test #{num}"
  repo_dir_name = File.join(base_repo_dir, settings.fixed_repo_name(repo_name))
  settings.add_repo(repo_name, repo_dir_name)
  FileUtils::mkpath(repo_dir_name)
  File.open(File.join(repo_dir_name, "test.txt"), 'w') do |out|
    out.write("data\n")
  end
end
settings.save()

