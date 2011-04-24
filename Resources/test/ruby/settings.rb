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
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: one empty file: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 0"=>[{"path"=>"sample.txt", "source"=>true, "reviewed"=>false, "ftype"=>"file"}]}]



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
      [{"test 0"=>[{"path"=>"sample.txt", "source"=>true, "reviewed"=>true, "ftype"=>"file"}]}]



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
         [{"path"=>"a_sub_dir", "source"=>true, "reviewed"=>false, "ftype"=>"directory",
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
         [{"path"=>File.join("1_sub_dir"),
            "source"=>true, "reviewed"=>false, "ftype"=>"directory",
            "contents"=>[File.join("11_sub_dir", "111_sub_dir", '1_sample.txt'),
                         File.join("11_sub_dir", "111_sub_dir", '1_sample2.txt'),
                         File.join("11_sub_dir", "112_sub_dir", '1121_sub_dir', '1_sample3.txt')]}]}]



    Updates.mark_reviewed(@settings, repo_test1, File.join(deeper1, "1_sample.txt"))
    Updates.mark_reviewed(@settings, repo_test1, File.join(deeper1, "1_sample2.txt"))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed files in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 1"=>
         [{"path"=>File.join("1_sub_dir", "11_sub_dir", "112_sub_dir"),
            "source"=>true, "reviewed"=>false, "ftype"=>"directory",
            "contents"=>[File.join('1121_sub_dir', '1_sample3.txt')]}]}]



    File.new(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '11_sub_dir', 'sample.txt'), 'w')
    Updates.mark_reviewed(@settings, repo_test1, File.join('1_sub_dir', '11_sub_dir'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed directory in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"test 1"=>
         [{"path"=>File.join("1_sub_dir", "11_sub_dir", "sample.txt"),
            "source"=>false, "reviewed"=>true, "ftype"=>"file"}]}]
    # As you can see, it leaves the file that was only in the reviewed files.
    # We may want to change this so it deletes (and warn the user profusely),
    # but for now it'll be 2 steps for the user: mark whole dir reviewed,
    # then eliminate old files individually.



    Updates.mark_reviewed(@settings, repo_test1, File.join('1_sub_dir', '11_sub_dir', 'sample.txt'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed removed file: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    FileUtils.rm_rf(File.join(repo_test1['source_dir'], '1_sub_dir', '11_sub_dir'))
    Updates.mark_reviewed(@settings, repo_test1, File.join('1_sub_dir', '11_sub_dir'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: removed entire subdirectory: #{all_repo_diffs.inspect}" if all_repo_diffs != []


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
puts "Remaining: file/dir mismatches"
#SettingsTest.rm_rf(File.join("build", "test-data"))
