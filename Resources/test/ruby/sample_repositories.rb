require 'fileutils'
require File.join(File.expand_path(File.dirname(__FILE__)), "../../ruby/settings.rb")

base_repo_dir = File.expand_path(File.join("build", "sample-repos"))
settings = Settings.new(base_repo_dir)

# make 1000 repositories
(0..20).each do |num|
#21 dies on #15
#23 dies on #15
#25 dies on #15
#30 dies on #14
#50 dies on #14 (or 12)
#100 dies on #6
#200 dies on #27
  repo_name = "test #{num}"
  repo_dir_name = File.join(base_repo_dir, settings.fixed_repo_name(repo_name))
  settings.add_repo(repo_name, repo_dir_name)
  FileUtils::mkpath(repo_dir_name)
#  File.open(File.join(repo_dir_name, "test 0.txt"), 'w') do |out|
#    out.write("data")
#  end
end
settings.save()

