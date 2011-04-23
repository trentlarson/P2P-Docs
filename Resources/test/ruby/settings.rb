require File.join(File.expand_path(File.dirname(__FILE__)), "../../ruby/settings.rb")
require File.join(File.expand_path(File.dirname(__FILE__)), "../../ruby/updates.rb")

class SettingsTest

  @test_data_dir
  @settings

  def initialize(base_build_dir = "build", test_data_dirname = "test-data", verbose = false)

    if (! File.exist? base_build_dir)
      Dir.mkdir(base_build_dir)
    end

    @test_data_dir = File.join(base_build_dir, test_data_dirname)
    puts "Removing " + @test_data_dir + " and everything underneath." if verbose
    SettingsTest.rm_rf(@test_data_dir)
    Dir.mkdir(@test_data_dir)

    # load blank settings, used to create a file of sample settings
    @settings = Settings.new(@test_data_dir)

  end

  def run()
    methods.sort.each{ |meth| send(meth) if meth.to_s.start_with? "test_" }
  end



  # Take a hash of settings properties and create the settings file,
  # and delete the old test directories and create new ones based on the given data.
  def setup_settings(settings_data)

    @settings.replace(settings_data)

    # set up the directory structure
    sources_dir = File.join(@settings.data_dir, "sources")
    SettingsTest.rm_rf(sources_dir)
    Dir.mkdir(sources_dir)
    SettingsTest.rm_rf(@settings.reviewed_base_dir)
    Dir.mkdir(@settings.reviewed_base_dir)
    if (settings_data['repositories'] != nil)
      settings_data['repositories'].each do |repo|
        Dir.mkdir(repo['source_dir'])
        Dir.mkdir(@settings.reviewed_dir(repo['name']))
      end
    end
  end

  def test_a()

    setup_settings(@settings.properties)

    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: diffs on no repos: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    repo_test0 = {'name'=>'test 0', 'source_dir'=>File.join(@test_data_dir, 'sources', 'hacked')}
    @settings.replace({'repositories'=>[repo_test0]})
    Dir.mkdir(repo_test0['source_dir'])
    Dir.mkdir(@settings.reviewed_dir(repo_test0))

    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: diffs on one blank repo: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    repo_test1 = {'name'=>'test 1', 'source_dir'=>File.join(@test_data_dir, 'sources', 'hacked-again')}
    @settings.replace({'repositories'=>[repo_test0, repo_test1]})
    Dir.mkdir(repo_test1['source_dir'])
    Dir.mkdir(@settings.reviewed_dir(repo_test1))

    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: diffs on two blank repos: #{all_repo_diffs.inspect}" if all_repo_diffs != []




    File.new(File.join(repo_test0['source_dir'], 'sample.txt'), 'w')
    File.new(File.join(@settings.reviewed_dir(repo_test0), 'sample.txt'), 'w')

    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: bad results of #{all_repo_diffs.inspect}" if all_repo_diffs != []



    File.new(File.join(@settings.reviewed_dir(repo_test0), 'sample1.txt'), 'w')
    File.new(File.join(@settings.reviewed_dir(repo_test0), 'sample2.txt'), 'w')

    all_repo_diffs = Updates.all_repo_diffs(@settings)    
    puts "fail: bad results of #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 0"=>
         [{"path"=>"sample1.txt", "source"=>false, "reviewed"=>true, "ftype"=>"file"},
          {"path"=>"sample2.txt", "source"=>false, "reviewed"=>true, "ftype"=>"file"}]}]



    sample = File.join(repo_test0['source_dir'], 'sample.txt')
    File.open(sample, 'w') do |out|
      out.write "gabba gabba hey\n"
    end

    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: bad results of #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 0"=>
         [{"path"=>"sample.txt", "source"=>true, "reviewed"=>true, "ftype"=>"file"},
          {"path"=>"sample1.txt", "source"=>false, "reviewed"=>true, "ftype"=>"file"},
          {"path"=>"sample2.txt", "source"=>false, "reviewed"=>true, "ftype"=>"file"}]}]



    repo_test1 = @settings.properties['repositories'].select{ |repo| repo['name'] == 'test 1' }[0]
    File.new(File.join(repo_test1['source_dir'], 'sample-again.txt'), 'w')

    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: bad results of #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 0"=>
         [{"path"=>"sample.txt", "source"=>true, "reviewed"=>true, "ftype"=>"file"},
          {"path"=>"sample1.txt", "source"=>false, "reviewed"=>true, "ftype"=>"file"},
          {"path"=>"sample2.txt", "source"=>false, "reviewed"=>true, "ftype"=>"file"}]},
       {"test 1"=>
         [{"path"=>"sample-again.txt", "source"=>true, "reviewed"=>false, "ftype"=>"file"}]}]
    


    Updates.mark_reviewed(@settings, repo_test1, "sample-again.txt")

    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: bad results of #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 0"=>
         [{"path"=>"sample.txt", "source"=>true, "reviewed"=>true, "ftype"=>"file"},
          {"path"=>"sample1.txt", "source"=>false, "reviewed"=>true, "ftype"=>"file"},
          {"path"=>"sample2.txt", "source"=>false, "reviewed"=>true, "ftype"=>"file"}]}]
    
  end

  # deprecated: use FileUtils.remove_entry_secure
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
puts "Remaining: subdirectories, file/dir mismatches, "
#SettingsTest.rm_rf(File.join("build", "test-data"))
