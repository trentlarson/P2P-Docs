#require "Resources/ruby/settings.rb"
#require "../settings.rb"

class SettingsTest

  def initialize(base_test_dir = "build")
    if (! File.exist? base_test_dir)
      Dir.mkdir(base_test_dir)
    end
    data_dir = File.join(base_test_dir, "test-data")
    if (! File.exist? data_dir)
      Dir.mkdir(data_dir)
    end

    require File.join(File.expand_path(File.dirname(__FILE__)), "../../ruby/settings.rb")
    @settings = Settings.new(data_dir)

    if (! File.exist? @settings.settings_file)
      File.open(@settings.settings_file, 'w') do |out|
        YAML.dump(test_properties, out)
      end
    end

    @settings = Settings.new(data_dir)

  end

  def run()
    @settings.data_dir
    methods.sort.each{ |meth| send(meth) if meth.to_s.start_with? "test_" }
  end

  def test_properties
    {'repositories'=>
       [{'name'=>'test 0', 'path'=>'/Users/tlarson/hacked'},
        {'name'=>'test 1', 'path'=>'/Users/tlarson/hacked-again'}]
    }
  end

  def test_dirs()
    puts "failure"
  end

end

SettingsTest.new.run
