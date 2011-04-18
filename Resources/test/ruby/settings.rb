require File.join(File.expand_path(File.dirname(__FILE__)), "../../ruby/settings.rb")
require File.join(File.expand_path(File.dirname(__FILE__)), "../../ruby/updates.rb")

class SettingsTest

  @data_dir
  @sources_dir
  @settings

  def initialize(base_test_dir = "build", test_data_dir = "test-data")

    @data_dir = File.join(base_test_dir, test_data_dir)
    puts "Removing " + @data_dir + " and everything underneath."
    SettingsTest.rm_rf(@data_dir)

    if (! File.exist? base_test_dir)
      Dir.mkdir(base_test_dir)
    end
    Dir.mkdir(@data_dir)

    # load blank settings, used to create a file of sample settings
    @settings = Settings.new(@data_dir)

    # now set up a sample directory structure and settings file
    @sources_dir = File.join(@data_dir, "sources")
    Dir.mkdir(@sources_dir)
    File.open(@settings.settings_file, 'w') do |out|
      settings = sample_settings(@sources_dir)
      settings['repositories'].each do |repo|
        Dir.mkdir(repo['path'])
      end
      YAML.dump(settings, out)
    end

    @settings = Settings.new(@data_dir)

  end

  def run()
    methods.sort.each{ |meth| send(meth) if meth.to_s.start_with? "test_" }
  end

  def sample_settings(base_dir)
    {'repositories'=>
       [{'name'=>'test 0', 'path'=>File.join(base_dir, 'hacked')},
        {'name'=>'test 1', 'path'=>File.join(base_dir, 'hacked-again')}]
    }
  end

  def test_dirs()
    File.new(File.join(@sources_dir, 'hacked', 'sample.txt'), 'w')

    Dir.mkdir(File.join(@settings.data_dir, 'accepted_files'))
    Dir.mkdir(File.join(@settings.data_dir, 'accepted_files', 'test_0'))
    File.new(File.join(@settings.data_dir, 'accepted_files', 'test_0', 'sample.txt'), 'w')
    #File.new(File.join(@settings.data_dir, 'accepted_files', 'test_0', 'sample1.txt'), 'w')
    #File.new(File.join(@settings.data_dir, 'accepted_files', 'test_0', 'sample2.txt'), 'w')

    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "test_dirs result: " + all_repo_diffs.to_s
  end

  def self.rm_rf(file)
    if (File.exist? file)
      if (File.file? file)
        File.delete file
      else
        Dir.foreach(file) do |subfile|
          if (subfile != '.' && subfile != '..')
            rm_rf File.join(file, subfile)
          end
        end
        Dir.delete(file)
      end
    end
  end

end

SettingsTest.new.run
puts "Next have to create an exhaustive list of combinations of differences!"
#SettingsTest.rm_rf(File.join("build", "test-data"))
