
class SettingsTest

  def initialize(base_test_dir = "build", test_data_dir = "test-data")
    if (! File.exist? base_test_dir)
      Dir.mkdir(base_test_dir)
    end

    @data_dir = File.join(base_test_dir, test_data_dir)
    SettingsTest.rm_rf(@data_dir)
    Dir.mkdir(@data_dir)

    require File.join(File.expand_path(File.dirname(__FILE__)), "../../ruby/settings.rb")
    @settings = Settings.new(@data_dir)

    @sources_dir = File.join(@data_dir, "sources")
    Dir.mkdir(@sources_dir)
    File.open(@settings.settings_file, 'w') do |out|
      settings = sample_properties(@sources_dir)
      settings['repositories'].each do |repo|
        Dir.mkdir repo['path']
      end
        
      YAML.dump(settings, out)
    end

    @settings = Settings.new(@data_dir)

  end

  def run()
    methods.sort.each{ |meth| send(meth) if meth.to_s.start_with? "test_" }
  end

  def sample_properties(base_dir)
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

    all_repo_diffs =
      @settings.properties['repositories'].collect do |repo|
        all_diffs(repo['path'], @settings.accepted_dir(repo), "")
          .collect { |subpath| repo['name'] + ":" + subpath }
      end.flatten
    puts "test_dirs result: " + all_repo_diffs.to_s
  end

  def all_diffs(source_dir, accepted_dir, subpath)
    source_file = File.join(source_dir, subpath)
    accepted_file = File.join(accepted_dir, subpath)
    if ((! File.exist? source_file) || (! File.exist? accepted_file))
      [subpath]
    elsif (File.file?(source_file) && File.file?(accepted_file))
      if (File.mtime(source_file) != File.mtime(accepted_file))
        [subpath]
      end
    elsif (File.directory?(source_file) && File.directory?(accepted_file))
      diff_subs = Dir.entries(source_file) | Dir.entries(accepted_file)
      diff_subs.reject! { |sub| sub == '.' || sub == '..' }
      diff_subs.map! { |entry| all_diffs(source_dir, accepted_dir, File.join(subpath, entry)) }
      diff_subs.flatten.compact
    else
      [subpath]
    end
  end

  def self.rm_rf(file)
    if (File.exist? file)
      puts "removing " + file
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
