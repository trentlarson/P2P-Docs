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
    FileUtils::remove_entry_secure(@test_data_dir, true)
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
    FileUtils::remove_entry_secure(sources_dir, true)
    Dir.mkdir(sources_dir)
    FileUtils::remove_entry_secure(@settings.reviewed_base_dir, true)
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
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: one empty file: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 0"=>[{"path"=>"sample.txt", "source"=>"file", "reviewed"=>nil}]}]



    sleep(1) # for testing modified time
    Updates.mark_reviewed(@settings, repo_test0, 'sample.txt')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: after review: #{all_repo_diffs.inspect}" if all_repo_diffs != []
    source_mtime = File.mtime(File.join(repo_test0['source_dir'], "sample.txt"))
    target_mtime = File.mtime(File.join(@settings.reviewed_dir(repo_test0), 'sample.txt'))
    puts "fail: different times: #{source_mtime} #{target_mtime}" if source_mtime != target_mtime



    File.open(File.join(repo_test0['source_dir'], 'sample.txt'), 'w') do |out|
      out.write "gabba gabba hey\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: one file with changed contents: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 0"=>[{"path"=>"sample.txt", "source"=>"file", "reviewed"=>"file"}]}]



    Updates.mark_reviewed(@settings, repo_test0, 'sample.txt')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: no changed files: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    Dir.mkdir(File.join(repo_test0['source_dir'], "a_sub_dir"))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: new empty source directory: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    File.open(File.join(repo_test0['source_dir'], 'a_sub_dir', 'a_sample.txt'), 'w') do |out|
      out.write "more gabba gabba hey\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    a_filename = File.join('a_sub_dir', 'a_sample.txt')
    puts "fail: new file in source directory: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 0"=>
         [{"path"=>"a_sub_dir", "source"=>"directory", "reviewed"=>nil,
            "contents"=>['a_sample.txt']}]}]



    Updates.mark_reviewed(@settings, repo_test0, a_filename)
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: all synched up: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    deeper1 = File.join('1_sub_dir', '11_sub_dir', '111_sub_dir')
    deeper2 = File.join('1_sub_dir', '11_sub_dir', '112_sub_dir', '1121_sub_dir')
    FileUtils::mkpath(File.join(repo_test1['source_dir'], deeper1))
    FileUtils::mkpath(File.join(repo_test1['source_dir'], deeper2))
    File.open(File.join(repo_test1['source_dir'], deeper1, '1_sample.txt'), 'w') do |out|
      out.write "less\n"
    end
    File.open(File.join(repo_test1['source_dir'], deeper1, '1_sample2.txt'), 'w') do |out|
      out.write "less\n"
    end
    File.open(File.join(repo_test1['source_dir'], deeper2, '1_sample3.txt'), 'w') do |out|
      out.write "less\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: new files in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 1"=>
         [{"path"=>File.join("1_sub_dir"), "source"=>"directory", "reviewed"=>nil,
            "contents"=>[File.join("11_sub_dir", "111_sub_dir", '1_sample.txt'),
                         File.join("11_sub_dir", "111_sub_dir", '1_sample2.txt'),
                         File.join("11_sub_dir", "112_sub_dir", '1121_sub_dir', '1_sample3.txt')]}]}]



    Updates.mark_reviewed(@settings, repo_test1, File.join(deeper1, "1_sample.txt"))
    Updates.mark_reviewed(@settings, repo_test1, File.join(deeper1, "1_sample2.txt"))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: source files in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 1"=>
         [{"path"=>File.join("1_sub_dir", "11_sub_dir", "112_sub_dir"),
            "source"=>"directory", "reviewed"=>nil,
            "contents"=>[File.join('1121_sub_dir', '1_sample3.txt')]}]}]



    File.new(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '11_sub_dir', 'sample.txt'), 'w')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: source & reviewed files in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 1"=>
         [{"path"=>File.join("1_sub_dir", "11_sub_dir", "112_sub_dir"),
            "source"=>"directory", "reviewed"=>nil,
            "contents"=>[File.join('1121_sub_dir', '1_sample3.txt')]},
          {"path"=>File.join("1_sub_dir", "11_sub_dir", "sample.txt"), "source"=>nil, "reviewed"=>"file"}]}]


    Updates.mark_reviewed(@settings, repo_test1, File.join('1_sub_dir', '11_sub_dir'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed directory in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    Updates.mark_reviewed(@settings, repo_test1, File.join('1_sub_dir', '11_sub_dir', 'sample.txt'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed removed file: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    FileUtils.rm_rf(File.join(repo_test1['source_dir'], '1_sub_dir', '11_sub_dir'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: removed entire source subdirectory: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 1"=>
         [{"path"=>File.join("1_sub_dir","11_sub_dir"), "source"=>nil, "reviewed"=>"directory",
            "contents"=>["111_sub_dir/1_sample.txt",
                         "111_sub_dir/1_sample2.txt",
                         "112_sub_dir/1121_sub_dir/1_sample3.txt"]}]}]



    Updates.mark_reviewed(@settings, repo_test1, File.join('1_sub_dir', '11_sub_dir'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed entire subdirectory: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    # mismatch file and dir
    Dir.rmdir(File.join(repo_test1['source_dir'], '1_sub_dir'))
    File.new(File.join(repo_test1['source_dir'], '1_sub_dir'), 'w')    
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: file vs dir: #{all_repo_diffs.inspect}" if all_repo_diffs != 
      [{"test 1"=>[{"path"=>"1_sub_dir", "source"=>"file", "reviewed"=>"directory"}]}]



    Updates.mark_reviewed(@settings, repo_test1, '1_sub_dir')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed file replaced dir: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    # mismatch dir and file
    FileUtils::rm_f(File.join(repo_test1['source_dir'], '1_sub_dir'))
    Dir.mkdir(File.join(repo_test1['source_dir'], '1_sub_dir'))
    File.new(File.join(repo_test1['source_dir'], '1_sub_dir', '1_sample.txt'), 'w')    
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: dir vs file: #{all_repo_diffs.inspect}" if all_repo_diffs != 
      [{"test 1"=>[{"path"=>"1_sub_dir", "source"=>"directory", "reviewed"=>"file",
                     "contents"=>["1_sample.txt"]}]}]



    Updates.mark_reviewed(@settings, repo_test1, '1_sub_dir')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed dir replaced file: #{all_repo_diffs.inspect}" if all_repo_diffs != []

  end

end

SettingsTest.new.run
