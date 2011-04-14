#require "Resources/ruby/settings.rb"
#require "../settings.rb"

class SettingsTest

  def initialize(base_test_dir)
    require File.join(File.expand_path(File.dirname(__FILE__)), "../ruby/settings.rb")
    #require File.join(File.dirname(__FILE__), "../ruby/settings.rb")

    puts $:
    settings = Settings.new(base_test_dir + "test-data")
    Dir.new(File.join(base_test_dir, "test-repos"))
    Dir.new(File.join(base_test_dir, ""))
  end

  def run()
    methods.sort.each{ |meth| send(meth) if meth.to_s.start_with? "test_" }
  end

  def test_dirs()
    puts "failure"
  end

end
