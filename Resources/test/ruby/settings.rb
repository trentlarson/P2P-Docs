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
        Dir.mkdir(repo['incoming_loc'])
      end
    end
  end

  def test_repo_names()
    name = "test_this-thing_here-_"
    puts "fail: #{name} doesn't match expected" if @settings.fixed_repo_name(name) != name
    name = "4nd_4n0th3r_Th1ng"
    puts "fail: #{name} doesn't match expected" if @settings.fixed_repo_name(name) != name
    name = "No spaces"
    puts "fail: #{name} doesn't match expected" if @settings.fixed_repo_name(name) != "No_spaces"
    name = "0!@\#$%^&*()/12"
    puts "fail: #{name} doesn't match expected" if @settings.fixed_repo_name(name) != "0___________12"
  end
  
  def test_repo_creation()
    setup_settings({'repositories' => []})
    repo = @settings.add_repo("", @test_data_dir + "/anywhere/for/fail")
    puts "fail: added repo with blank name" if repo != nil
    
    repo_name = "Test for dup"
    repo = @settings.add_repo(repo_name, @test_data_dir + "/some/funky/dir")
    puts "fail: didn't add test repo" if repo == nil
    puts "fail: repo doesn't have ID of 0" if repo['id'] != 0
    puts "fail: didn't create reviewed folder" if !(File.exist? @settings.reviewed_dir(repo))
    repo = @settings.add_repo(repo_name, @test_data_dir + "/another/funky/dir")
    puts "fail: added duplicate test repo" if repo != nil
    repo = @settings.add_repo(@settings.fixed_repo_name(repo_name), @test_data_dir + "/another/funky/dir/2")
    puts "fail: added duplicate test repo with fixed name" if repo != nil
    @settings.remove_repo(repo_name)
    puts "fail: didn't remove reviewed folder" if File.exist? @settings.reviewed_dir(repo_name)
    
    repo = @settings.add_repo(@settings.fixed_repo_name(repo_name), @test_data_dir + "/some/funky/dir")
    puts "fail: didn't add test repo after removal" if repo == nil
    puts "fail: repo doesn't have ID of 0 after removal" if repo['id'] != 0
    repo = @settings.add_repo(repo_name, @test_data_dir + "/another/funky/dir")
    puts "fail: added duplicate test repo matching fixed name" if repo != nil
    @settings.remove_repo(@settings.fixed_repo_name(repo_name))
    
    repo = @settings.add_repo(repo_name, @test_data_dir + "/some/funky/dir")
    puts "fail: didn't add test repo after 2nd removal" if repo == nil
    repo = @settings.add_repo(repo_name + "2", @test_data_dir + "/some/funky/dir2")
    puts "fail: repo doesn't have ID of 1" if repo['id'] != 1
  end
  
  def test_simple_json()
    test = nil
    puts "fail: bad json encoding of #{test}" if Updates.strings_arrays_hashes_json(test) != 
      "null"
    
    test = "junk"
    puts "fail: bad json encoding of #{test}" if Updates.strings_arrays_hashes_json(test) != 
      "\"junk\""
    
    # I had to do this because Macs have stupid "Icon\n" files.
    test = "junk\"\\/\b\f\n\r\t"
    want = "\"junk\\\"\\\\/\\b\\f\\n\\r\\t\""
    puts "fail: bad json encoding\n test: #{test}\n got:  #{Updates.strings_arrays_hashes_json(test)}\n want: #{want}" if
      Updates.strings_arrays_hashes_json(test) != want
    
    test = []
    want = "[]"
    puts "fail: bad json encoding\n test: #{test}\n got:  #{Updates.strings_arrays_hashes_json(test)}\n want: #{want}" if
      Updates.strings_arrays_hashes_json(test) != want
    
    test = [nil,"junk2","junk\"3\"",nil]
    want = "[null, \"junk2\", \"junk\\\"3\\\"\", null]"
    puts "fail: bad json encoding\n test: #{test}\n got:  #{Updates.strings_arrays_hashes_json(test)}\n want: #{want}" if
      Updates.strings_arrays_hashes_json(test) != want
    
    test = [nil,"junk2",["junk31",nil],[nil,[],["junk43"]]]
    want = "[null, \"junk2\", [\"junk31\", null], [null, [], [\"junk43\"]]]"
    puts "fail: bad json encoding\n test: #{test}\n got:  #{Updates.strings_arrays_hashes_json(test)}\n want: #{want}" if
      Updates.strings_arrays_hashes_json(test) != want
    
    test = {}
    want = "{}"
    puts "fail: bad json encoding\n test: #{test}\n got:  #{Updates.strings_arrays_hashes_json(test)}\n want: #{want}" if
      Updates.strings_arrays_hashes_json(test) != want

    test = { "akey" => "aval", "bkey" => "bval", "ckey" => "cval" }
    want = "{\"akey\":\"aval\", \"bkey\":\"bval\", \"ckey\":\"cval\"}"
    puts "fail: bad json encoding\n test: #{test}\n got:  #{Updates.strings_arrays_hashes_json(test)}\n want: #{want}" if
      Updates.strings_arrays_hashes_json(test) != want
    
    test = { "akey" => nil, "bkey" => ["bval1","bval2"], "ckey" => [], "dkey" => {"dkey1" => "dval1", "ekey1" => {"ekey11" => ["eval11",nil]}} }
    want = "{\"akey\":null, \"bkey\":[\"bval1\", \"bval2\"], \"ckey\":[], \"dkey\":{\"dkey1\":\"dval1\", \"ekey1\":{\"ekey11\":[\"eval11\", null]}}}"
    puts "fail: bad json encoding\n test: #{test}\n got:  #{Updates.strings_arrays_hashes_json(test)}\n want: #{want}" if
      Updates.strings_arrays_hashes_json(test) != want
    
  end

  def test_repo_diffs()

    setup_settings({'repositories'=>[]})
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: diffs on no repos: #{all_repo_diffs.inspect}" if all_repo_diffs != []



=begin
    # This test shows how it doesn't work yet to point to a file as the source repo.
    # The problem is strange: the File.exist? check fails on the reviewed directory.
    repo_test_file = {'name'=>'test file', 'incoming_loc'=>File.join(@test_data_dir, 'sources', 'a_file.txt')}
    @settings.replace({'repositories'=>[repo_test_file]})
    puts "fail: repo file, where neither exists: #{all_repo_diffs}" if all_repo_diffs != []
    File.open(repo_test_file['incoming_loc'], 'w') do |out|
      out.write "Hey batta batta!\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: repo file, where source exists: #{all_repo_diffs.inspect}" if all_repo_diffs != 
      [{"name"=>"test file", "diffs"=>[{"path"=>"", "source"=>"file", "reviewed"=>nil, "contents"=>nil}]}]
    Dir.mkdir(@settings.reviewed_dir(repo_test_file))
    File.open(File.join(@settings.reviewed_dir(repo_test_file), 'a_file.txt'), 'w') do |out|
      out.write "Hey batta batta!\n"
    end
    puts "fail: repo file, where both exist: #{all_repo_diffs}" if all_repo_diffs != []
=end



    repo_test0 = {'id' => 0, 'name'=>'test 0', 'incoming_loc'=>File.join(@test_data_dir, 'sources', 'hacked')}
    @settings.replace({'repositories'=>[repo_test0]})
    Dir.mkdir(repo_test0['incoming_loc'])
    Dir.mkdir(@settings.reviewed_dir(repo_test0))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: diffs on one blank repo: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    repo_test1 = {'id' => 1, 'name'=>'test 1', 'incoming_loc'=>File.join(@test_data_dir, 'sources', 'hacked-again')}
    @settings.replace({'repositories'=>[repo_test0, repo_test1]})
    Dir.mkdir(repo_test1['incoming_loc'])
    Dir.mkdir(@settings.reviewed_dir(repo_test1))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: diffs on two blank repos: #{all_repo_diffs.inspect}" if all_repo_diffs != []




    File.new(File.join(repo_test0['incoming_loc'], 'sample.txt'), 'w')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: one empty file: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 0", "diffs"=>[{"path"=>"sample.txt", "source"=>"file", "reviewed"=>nil, "contents"=>nil}]}]



    sleep(1) # for testing modified time
    Updates.mark_reviewed(@settings, 'test 0', 'sample.txt')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: after review: #{all_repo_diffs.inspect}" if all_repo_diffs != []
    source_mtime = File.mtime(File.join(repo_test0['incoming_loc'], "sample.txt"))
    target_mtime = File.mtime(File.join(@settings.reviewed_dir(repo_test0), 'sample.txt'))
    puts "fail: different times: #{source_mtime} #{target_mtime}" if source_mtime != target_mtime



    File.open(File.join(repo_test0['incoming_loc'], 'sample.txt'), 'w') do |out|
      out.write "gabba gabba hey\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: one file with changed contents: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 0", "diffs"=>[{"path"=>"sample.txt", "source"=>"file", "reviewed"=>"file", "contents"=>nil}]}]



    Updates.mark_reviewed(@settings, 'test 0', 'sample.txt')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: no changed files: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    File.open(File.join(repo_test0['incoming_loc'], 'sample.txt'), 'w') do |out|
      out.write "mitch\n"
    end
    File.new(File.join(repo_test1['incoming_loc'], '1_sample.txt'), 'w')
    Updates.mark_reviewed(@settings, 'test 1', '1_sample.txt')
    File.open(File.join(repo_test1['incoming_loc'], '1_sample.txt'), 'w') do |out|
      out.write "yabba dabba doo\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: two different files: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 0", "diffs"=>[{"path"=>"sample.txt", "source"=>"file", "reviewed"=>"file", "contents"=>nil}]},
       {"name"=>"test 1", "diffs"=>[{"path"=>"1_sample.txt", "source"=>"file", "reviewed"=>"file", "contents"=>nil}]}]



    Updates.mark_reviewed(@settings, 'test 0', 'sample.txt')
    Updates.mark_reviewed(@settings, 'test 1', '1_sample.txt')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: no changed files: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    Dir.mkdir(File.join(repo_test0['incoming_loc'], "a_sub_dir"))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: new empty source directory: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    File.open(File.join(repo_test0['incoming_loc'], 'a_sub_dir', 'a_sample.txt'), 'w') do |out|
      out.write "more gabba gabba hey\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    a_filename = File.join('a_sub_dir', 'a_sample.txt')
    puts "fail: new file in source directory: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 0",
        "diffs" =>
         [{"path"=>"a_sub_dir", "source"=>"directory", "reviewed"=>nil,
            "contents"=>['a_sample.txt']}]}]



    Updates.mark_reviewed(@settings, 'test 0', a_filename)
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: all synched up: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    deeper1 = File.join('1_sub_dir', '11_sub_dir', '111_sub_dir')
    deeper2 = File.join('1_sub_dir', '11_sub_dir', '112_sub_dir', '1121_sub_dir')
    FileUtils::mkpath(File.join(repo_test1['incoming_loc'], deeper1))
    FileUtils::mkpath(File.join(repo_test1['incoming_loc'], deeper2))
    File.open(File.join(repo_test1['incoming_loc'], deeper1, '1_sample.txt'), 'w') do |out|
      out.write "less\n"
    end
    File.open(File.join(repo_test1['incoming_loc'], deeper1, '1_sample2.txt'), 'w') do |out|
      out.write "less\n"
    end
    File.open(File.join(repo_test1['incoming_loc'], deeper2, '1_sample3.txt'), 'w') do |out|
      out.write "less\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: new files in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 1",
         "diffs"=>
         [{"path"=>File.join("1_sub_dir"), "source"=>"directory", "reviewed"=>nil,
            "contents"=>[File.join("11_sub_dir", "111_sub_dir", '1_sample.txt'),
                         File.join("11_sub_dir", "111_sub_dir", '1_sample2.txt'),
                         File.join("11_sub_dir", "112_sub_dir", '1121_sub_dir', '1_sample3.txt')]}]}]



    Updates.mark_reviewed(@settings, 'test 1', File.join(deeper1, "1_sample.txt"))
    Updates.mark_reviewed(@settings, 'test 1', File.join(deeper1, "1_sample2.txt"))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: source files in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 1",
         "diffs"=>
         [{"path"=>File.join("1_sub_dir", "11_sub_dir", "112_sub_dir"),
            "source"=>"directory", "reviewed"=>nil,
            "contents"=>[File.join('1121_sub_dir', '1_sample3.txt')]}]}]



    File.new(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '11_sub_dir', 'sample.txt'), 'w')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: source & reviewed files in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 1",
         "diffs"=>
         [{"path"=>File.join("1_sub_dir", "11_sub_dir", "112_sub_dir"),
            "source"=>"directory", "reviewed"=>nil,
            "contents"=>[File.join('1121_sub_dir', '1_sample3.txt')]},
          {"path"=>File.join("1_sub_dir", "11_sub_dir", "sample.txt"), "source"=>nil, "reviewed"=>"file", "contents"=>nil}]}]


    Updates.mark_reviewed(@settings, 'test 1', File.join('1_sub_dir', '11_sub_dir'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed directory in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    Updates.mark_reviewed(@settings, 'test 1', File.join('1_sub_dir', '11_sub_dir', 'sample.txt'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed removed file: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    FileUtils.rm_rf(File.join(repo_test1['incoming_loc'], '1_sub_dir', '11_sub_dir'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: removed entire source subdirectory: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 1",
         "diffs"=>
         [{"path"=>File.join("1_sub_dir","11_sub_dir"), "source"=>nil, "reviewed"=>"directory",
            "contents"=>["111_sub_dir/1_sample.txt",
                         "111_sub_dir/1_sample2.txt",
                         "112_sub_dir/1121_sub_dir/1_sample3.txt"]}]}]



    Updates.mark_reviewed(@settings, 'test 1', File.join('1_sub_dir', '11_sub_dir'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed entire subdirectory: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    # mismatch file and dir
    Dir.rmdir(File.join(repo_test1['incoming_loc'], '1_sub_dir'))
    File.new(File.join(repo_test1['incoming_loc'], '1_sub_dir'), 'w')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: file vs dir: #{all_repo_diffs.inspect}" if all_repo_diffs != 
      [{"name"=>"test 1",
         "diffs"=>[{"path"=>"1_sub_dir", "source"=>"file", "reviewed"=>"directory", "contents"=>[]}]}]



    Updates.mark_reviewed(@settings, 'test 1', '1_sub_dir')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed file replaced dir: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    # mismatch dir and file
    FileUtils::rm_f(File.join(repo_test1['incoming_loc'], '1_sub_dir'))
    Dir.mkdir(File.join(repo_test1['incoming_loc'], '1_sub_dir'))
    File.new(File.join(repo_test1['incoming_loc'], '1_sub_dir', '1_sample.txt'), 'w')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: dir vs file: #{all_repo_diffs.inspect}" if all_repo_diffs != 
      [{"name"=>"test 1",
         "diffs"=>
         [{"path"=>"1_sub_dir", "source"=>"directory", "reviewed"=>"file", "contents"=>["1_sample.txt"]}]}]



    Updates.mark_reviewed(@settings, 'test 1', '1_sub_dir')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed dir replaced file: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    # symlink, existent
    FileUtils.rm(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    File.symlink(File.join("..", "..", "..", 'settings.yaml'),
                 File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: mismatch file types w/ good link: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 1",
         "diffs"=>[{"path"=>"1_sub_dir/1_sample.txt", "source"=>"file", "reviewed"=>"file", "contents"=>nil}]}]



    # symlink nonexistent
    FileUtils.rm(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    File.symlink(File.join("..", "..", 'settings.yaml'),
                 File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: mismatch file types w/ bad link: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 1",
         "diffs"=>[{"path"=>"1_sub_dir/1_sample.txt", "source"=>"file", "reviewed"=>nil, "contents"=>nil}]}]



    # characterSpecial
    FileUtils.rm(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    File.symlink("/dev/tty",
                 File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: mismatch file types: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 1",
         "diffs"=>[{"path"=>"1_sub_dir/1_sample.txt", "source"=>"file", "reviewed"=>"link", "contents"=>nil}]}]



    Updates.mark_reviewed(@settings, 'test 1', '1_sub_dir')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed dir replaced file: #{all_repo_diffs.inspect}" if all_repo_diffs != []

  end

end

SettingsTest.new.run
#SettingsTest.new.test_simple_json
#SettingsTest.new.test_repo_creation
#SettingsTest.new.test_repo_diffs
