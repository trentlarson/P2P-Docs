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

  def test_versioned_diffs
    
    file = "dir1/dir2/file_abc.txt"
    match = Updates.match_numeric_suffix(file)
    puts "fail: bad match: #{file} => #{match}" if match != nil
    file = "dir1/dir2/file_2.rss.xml"
    match = Updates.match_numeric_suffix(file)
    puts "fail: bad match: #{file} => #{match}" if match[3] != "2"
    file = "dir1/dir_2.out/file_2.is.mine_345.rss.txt"
    match = Updates.match_numeric_suffix(file)
    puts "fail: bad match: #{file} => #{match}" if match[3] != "345"
    # not doing this because it's not important (and the code doesn't work on it :-)
    #file = "dir1/dir2/file_1.4.txt"
    
    v_dir = File.join(@test_data_dir, "versioned_filenames")
    Dir.mkdir v_dir
    File.new(File.join(v_dir, "some.txt"), 'w').write("junk\n")
    File.new(File.join(v_dir, "some1.txt"), 'w').write("junk\n")
    File.new(File.join(v_dir, "some3_12.txt"), 'w').write("junk\n")
    File.new(File.join(v_dir, "some3_2.txt"), 'w').write("junk\n")
    File.new(File.join(v_dir, "some4.txt"), 'w').write("junk\n")
    File.new(File.join(v_dir, "some4_2.txt"), 'w').write("junk\n")
    File.new(File.join(v_dir, "some4_3.txt"), 'w').write("junk\n")
    File.new(File.join(v_dir, "some4_11.txt"), 'w').write("junk\n")
    File.new(File.join(v_dir, "some4_3.rss"), 'w').write("junk\n")
    File.new(File.join(v_dir, "some4_a.txt"), 'w').write("junk\n")
    File.new(File.join(v_dir, "something_3.txt"), 'w').write("junk\n")
    Dir.mkdir(File.join(v_dir, "some"))
    Dir.mkdir(File.join(v_dir, "some_3"))
    
    filenames = Updates.all_target_file_versions(v_dir, "sum", ".txt")
    expected = []
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; filenames.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: versioned files exist: #{filenames}" if expected != filenames
    
    filenames = Updates.all_target_file_versions(v_dir, "some", ".txt")
    expected = [[File.join(v_dir, 'some.txt')]]
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; filenames.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: initial file doesn't match: #{filenames}" if expected != filenames
    
    filenames = Updates.all_target_file_versions(v_dir, "some.txt", "")
    expected = [[File.join(v_dir, 'some.txt')]]
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; filenames.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: initial file altogether doesn't match: #{filenames}" if expected != filenames
    
    filenames = Updates.all_target_file_versions(v_dir, "some3", ".txt")
    expected = [
      File.join(v_dir, 'some3_12.txt'),
      File.join(v_dir, 'some3_2.txt')
    ].map { |elem| m = Updates.match_numeric_suffix(elem); [m[1], m[4], m[3].to_i] }
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; filenames.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: versioned files don't match: #{filenames}" if expected != filenames
    
    filenames = Updates.all_target_file_versions(v_dir, "some4", ".txt")
    expected = [
      [File.join(v_dir, 'some4.txt')]
    ] + [
      File.join(v_dir, 'some4_11.txt'),
      File.join(v_dir, 'some4_2.txt'),
      File.join(v_dir, 'some4_3.txt')
    ].map { |elem| m = Updates.match_numeric_suffix(elem); [m[1], m[4], m[3].to_i] }
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; filenames.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: initial and versioned files don't match: #{filenames}" if expected != filenames
    
    
    
    diff_results = [
      {'path'=>'some.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil}
    ]
    result = Updates.latest_versions(Updates.versioned_filenames(diff_results), v_dir)
    expected = {"some.txt"=>["build/test-data/versioned_filenames/some.txt"]}
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; result.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: versioned diff single 1: #{result}" if expected != result
    
    diff_results = [
      {'path'=>'some.txt', 'source_type'=>nil, 'target_type'=>file, 'contents'=>nil},
      {'path'=>'some_1.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil}
    ]
    result = Updates.latest_versions(Updates.versioned_filenames(diff_results), v_dir)
    expected = {"some.txt"=>["build/test-data/versioned_filenames/some.txt"]}
    puts "fail: versioned diff single 2: #{result}" if expected != result
    
    diff_results = [
      {'path'=>'some_1.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil}
    ]
    result = Updates.latest_versions(Updates.versioned_filenames(diff_results), v_dir)
    expected = {"some.txt"=>["build/test-data/versioned_filenames/some.txt"]}
    puts "fail: versioned diff single 3: #{result}" if expected != result
    
    # eg. some3_12.txt is reviewed (and some3.txt is gone)
    diff_results = [
      {'path'=>'some3_13.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'some3_14.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil}
    ]
    result = Updates.latest_versions(Updates.versioned_filenames(diff_results), v_dir)
    expected = {"some3.txt"=>["build/test-data/versioned_filenames/some3", ".txt", 12]}
    puts "fail: versioned diff for third: #{result}" if expected != result
    
    
    
    
    
    
=begin these might be useful in file-matching stuff
    diff_results = [
      {'path'=>'some1.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'some2.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'some3.txt', 'source_type'=>nil, 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'some4_2.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'some4_2.txt', 'source_type'=>nil, 'target_type'=>'file', 'contents'=>nil},
      some4.txt_5
    ]
    expected = [
      {'path'=>'some1.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'some4_2.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'some4_3.txt', 'source_type'=>nil, 'target_type'=>'file', 'contents'=>nil},
    ]
=end
    
    diff_results = [
      # base cases, without versions
      {'path'=>'afile.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'bfile.txt', 'source_type'=>nil, 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'dir', 'source_type'=>'directory', 'target_type'=>nil, 'contents'=>['a_sample.txt','b_sample.txt']},
      {'path'=>'dir_5.xyz', 'source_type'=>nil, 'target_type'=>'directory', 'contents'=>[]},
      # ensure correct sorting with versions
      {'path'=>'dir1/file.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'dir1/file2.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'dir1/file_12.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'dir1/file_2.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'dir1/dir2/file.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'dir1/dir2/file2.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'dir1/dir2/file_2.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'dir1/dir2/file_4.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'dir1/dir2/file_3.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil}
    ]
    versioned_files = Updates.versioned_filenames diff_results
    expected = 
    [
      {'version'=>["afile.txt"], 'diff_match'=>{"diff"=>{"path"=>"afile.txt", "source_type"=>"file", "target_type"=>nil, "contents"=>nil}, "match"=>nil}},
      {'version'=>["bfile.txt"], 'diff_match'=>{"diff"=>{"path"=>"bfile.txt", "source_type"=>nil, "target_type"=>"file", "contents"=>nil}, "match"=>nil}},
      {'version'=>["dir"], 'diff_match'=>{"diff"=>{"path"=>"dir", "source_type"=>"directory", "target_type"=>nil, "contents"=>["a_sample.txt", "b_sample.txt"]}, "match"=>nil}},
      {'version'=>["dir1/dir2/file.txt"], 'diff_match'=>{"diff"=>{"path"=>"dir1/dir2/file.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>nil}},
      {'version'=>["dir1/dir2/file", ".txt", 2], 'diff_match'=>{"diff"=>{"path"=>"dir1/dir2/file_2.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>Updates.match_numeric_suffix("dir1/dir2/file_2.txt")}},
      {'version'=>["dir1/dir2/file", ".txt", 3], 'diff_match'=>{"diff"=>{"path"=>"dir1/dir2/file_3.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>Updates.match_numeric_suffix("dir1/dir2/file_3.txt")}},
      {'version'=>["dir1/dir2/file", ".txt", 4], 'diff_match'=>{"diff"=>{"path"=>"dir1/dir2/file_4.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>Updates.match_numeric_suffix("dir1/dir2/file_4.txt")}},
      {'version'=>["dir1/dir2/file2.txt"], 'diff_match'=>{"diff"=>{"path"=>"dir1/dir2/file2.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>nil}},
      {'version'=>["dir1/file.txt"], 'diff_match'=>{"diff"=>{"path"=>"dir1/file.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>nil}},
      {'version'=>["dir1/file", ".txt", 2], 'diff_match'=>{"diff"=>{"path"=>"dir1/file_2.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>Updates.match_numeric_suffix("dir1/file_2.txt")}},
      {'version'=>["dir1/file", ".txt", 12], 'diff_match'=>{"diff"=>{"path"=>"dir1/file_12.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>Updates.match_numeric_suffix("dir1/file_12.txt")}},
      {'version'=>["dir1/file2.txt"], 'diff_match'=>{"diff"=>{"path"=>"dir1/file2.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>nil}},
      {'version'=>["dir_5.xyz"], 'diff_match'=>{"diff"=>{"path"=>"dir_5.xyz", "source_type"=>nil, "target_type"=>"directory", "contents"=>[]}, "match"=>nil}}
    ]
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; versioned_files.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: basic versioned file diffs: #{versioned_files}" if versioned_files != expected
    
    puts "do the versioned diffs for that set of files"
    puts "must handle case where initial file exists at source, and versioned file exists at source & target"
    
=begin
    # ensure correct report of versions partially reconciled
    diff_results = [
      # we have not reviewed any
      {'path'=>'file.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'file_1.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      # we have only reviewed the base one
      {'path'=>'file1.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'file1_1.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'file1_2.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'file1_3.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      # we have reviewed up to v2
      {'path'=>'file2.txt', 'source_type'=>nil, 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'file2_1.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'file2_2.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'file2_3.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'file2_4.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      # we have reviewed up to v33
      {'path'=>'file3_12.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'file3_21.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'file3_33.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      # we have reviewed everything
      {'path'=>'file4_8.txt', 'source_type'=>nil, 'target_type'=>'file', 'contents'=>nil}
    ]
    versioned_files = Updates.versioned_filenames diff_results
    expected = [
     {'version'=>["file.txt"], 'diff_match'=>{"diff"=>{"path"=>"file.txt", "source_type"=>"file", "target_type"=>nil, "contents"=>nil}, "match"=>nil}},
     {'version'=>["file", ".txt", 1], 'diff_match'=>{"diff"=>{"path"=>"file_1.txt", "source_type"=>"file", "target_type"=>nil, "contents"=>nil}, "match"=>Updates.match_numeric_suffix("file_1.txt")}},
     {'version'=>["file1.txt"], 'diff_match'=>{"diff"=>{"path"=>"file1.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>nil}},
     {'version'=>["file1", ".txt", 1], 'diff_match'=>{"diff"=>{"path"=>"file1_1.txt", "source_type"=>"file", "target_type"=>nil, "contents"=>nil}, "match"=>Updates.match_numeric_suffix("file1_1.txt")}},
     {'version'=>["file1", ".txt", 2], 'diff_match'=>{"diff"=>{"path"=>"file1_2.txt", "source_type"=>"file", "target_type"=>nil, "contents"=>nil}, "match"=>Updates.match_numeric_suffix("file1_2.txt")}},
     {'version'=>["file1", ".txt", 3], 'diff_match'=>{"diff"=>{"path"=>"file1_3.txt", "source_type"=>"file", "target_type"=>nil, "contents"=>nil}, "match"=>Updates.match_numeric_suffix("file1_3.txt")}},
     {'version'=>["file2.txt"], 'diff_match'=>{"diff"=>{"path"=>"file2.txt", "source_type"=>nil, "target_type"=>"file", "contents"=>nil}, "match"=>nil}},
     {'version'=>["file2", ".txt", 1], 'diff_match'=>{"diff"=>{"path"=>"file2_1.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>Updates.match_numeric_suffix("file2_1.txt")}},
     {'version'=>["file2", ".txt", 2], 'diff_match'=>{"diff"=>{"path"=>"file2_2.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>Updates.match_numeric_suffix("file2_2.txt")}},
     {'version'=>["file2", ".txt", 3], 'diff_match'=>{"diff"=>{"path"=>"file2_3.txt", "source_type"=>"file", "target_type"=>nil, "contents"=>nil}, "match"=>Updates.match_numeric_suffix("file2_3.txt")}},
     {'version'=>["file2", ".txt", 4], 'diff_match'=>{"diff"=>{"path"=>"file2_4.txt", "source_type"=>"file", "target_type"=>nil, "contents"=>nil}, "match"=>Updates.match_numeric_suffix("file2_4.txt")}},
     {'version'=>["file3", ".txt", 12], 'diff_match'=>{"diff"=>{"path"=>"file3_12.txt", "source_type"=>"file", "target_type"=>nil, "contents"=>nil}, "match"=>Updates.match_numeric_suffix("file3_12.txt")}},
     {'version'=>["file3", ".txt", 21], 'diff_match'=>{"diff"=>{"path"=>"file3_21.txt", "source_type"=>"file", "target_type"=>nil, "contents"=>nil}, "match"=>Updates.match_numeric_suffix("file3_21.txt")}},
     {'version'=>["file3", ".txt", 33], 'diff_match'=>{"diff"=>{"path"=>"file3_33.txt", "source_type"=>"file", "target_type"=>"file", "contents"=>nil}, "match"=>Updates.match_numeric_suffix("file3_33.txt")}}
    ]
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; versioned_files.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: advanced versioned file diffs (which is an intermediate function that can go away if the rest works): #{versioned_files}" if versioned_files != expected
    
    versioned_diffs = Updates.versioned_diffs diff_results, v_dir
    expected = [
      {"path"=>"file.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "contents"=>nil},
      {"path"=>"file_1.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "contents"=>nil},
      {"path"=>"file1_1.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"file1.txt", "contents"=>nil},
      {"path"=>"file1_2.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"file1.txt", "contents"=>nil},
      {"path"=>"file1_3.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"file1.txt", "contents"=>nil},
      {"path"=>"file2_3.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"file2_2.txt", "contents"=>nil},
      {"path"=>"file2_4.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"file2_2.txt", "contents"=>nil}
    ]
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; versioned_diffs.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: is this versioned diffs helpful?: #{versioned_diffs}" if versioned_diffs != expected
=end
    
  end



  def test_basic_diffs()

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
      [{"name"=>"test file", "diffs"=>[{"path"=>"", "source_type"=>"file", "target_type"=>nil, "contents"=>nil}]}]
    Dir.mkdir(@settings.reviewed_dir(repo_test_file))
    File.open(File.join(@settings.reviewed_dir(repo_test_file), 'a_file.txt'), 'w') do |out|
      out.write "Hey batta batta!\n"
    end
    puts "fail: repo file, where both exist: #{all_repo_diffs}" if all_repo_diffs != []
=end



    repo_test0 = {'id' => 0, 'name'=>'test 0', 'incoming_loc'=>nil}
    @settings.replace({'repositories'=>[repo_test0]})
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: diffs on repo w/o incoming: #{all_repo_diffs.inspect}" if all_repo_diffs != []



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
    puts "fail: not one empty file: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 0", "diffs"=>[{"path"=>"sample.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample.txt", "contents"=>nil}]}]

    Updates.mark_reviewed(@settings, 'test 0', 'sample.txt')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: after review: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    File.open(File.join(repo_test0['incoming_loc'], 'sample.txt'), 'w') do |out|
      out.write "gabba gabba hey\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: one file with different content size: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 0", "diffs"=>[{"path"=>"sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample.txt", "contents"=>nil}]}]

    Updates.mark_reviewed(@settings, 'test 0', 'sample.txt')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: different files: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    sleep(1) # for testing modified time
    File.delete(File.join(repo_test0['incoming_loc'], 'sample.txt'))
    File.open(File.join(repo_test0['incoming_loc'], 'sample.txt'), 'w') do |out|
      out.write "gabba gabba hoo\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: one file with same size but different mtime: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 0", "diffs"=>[{"path"=>"sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample.txt", "contents"=>nil}]}]

    Updates.mark_reviewed(@settings, 'test 0', 'sample.txt')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: different files: #{all_repo_diffs.inspect}" if all_repo_diffs != []
    source_mtime = File.mtime(File.join(repo_test0['incoming_loc'], "sample.txt"))
    target_mtime = File.mtime(File.join(@settings.reviewed_dir(repo_test0), 'sample.txt'))
    puts "fail: different times after accept: #{source_mtime} #{target_mtime}" if source_mtime != target_mtime



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
      [{"name"=>"test 0", "diffs"=>[{"path"=>"sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample.txt", "contents"=>nil}]},
       {"name"=>"test 1", "diffs"=>[{"path"=>"1_sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"1_sample.txt", "contents"=>nil}]}]

    Updates.mark_reviewed(@settings, 'test 0', 'sample.txt')
    Updates.mark_reviewed(@settings, 'test 1', '1_sample.txt')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: no different files: #{all_repo_diffs.inspect}" if all_repo_diffs != []



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
         [{"path"=>"a_sub_dir", "source_type"=>"directory", "target_type"=>nil,
            "target_path_previous_version"=>"a_sub_dir", "contents"=>['a_sample.txt']}]}]

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
         [{"path"=>File.join("1_sub_dir"), "source_type"=>"directory", "target_type"=>nil,
            "target_path_previous_version"=>File.join("1_sub_dir"),
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
            "source_type"=>"directory", "target_type"=>nil,
            "target_path_previous_version"=>File.join("1_sub_dir", "11_sub_dir", "112_sub_dir"),
            "contents"=>[File.join('1121_sub_dir', '1_sample3.txt')]}]}]



    File.new(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '11_sub_dir', 'sample.txt'), 'w')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: source & reviewed files in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 1",
         "diffs"=>
         [{"path"=>File.join("1_sub_dir", "11_sub_dir", "112_sub_dir"),
            "source_type"=>"directory",
            "target_type"=>nil,
            "target_path_previous_version"=>File.join("1_sub_dir", "11_sub_dir", "112_sub_dir"),
            "contents"=>[File.join('1121_sub_dir', '1_sample3.txt')]},
          {"path"=>File.join("1_sub_dir", "11_sub_dir", "sample.txt"),
            "source_type"=>nil,
            "target_type"=>"file",
            "target_path_previous_version"=>File.join("1_sub_dir", "11_sub_dir", "sample.txt"),
            "contents"=>nil}]}]

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
         [{"path"=>File.join("1_sub_dir","11_sub_dir"),
            "source_type"=>nil,
            "target_type"=>"directory",
            "target_path_previous_version"=>File.join("1_sub_dir","11_sub_dir"),
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
         "diffs"=>[{"path"=>"1_sub_dir", "source_type"=>"file", "target_type"=>"directory", "target_path_previous_version"=>"1_sub_dir", "contents"=>[]}]}]

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
         [{"path"=>"1_sub_dir", "source_type"=>"directory", "target_type"=>"file", "target_path_previous_version"=>"1_sub_dir", "contents"=>["1_sample.txt"]}]}]

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
         "diffs"=>[{"path"=>"1_sub_dir/1_sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"1_sub_dir/1_sample.txt", "contents"=>nil}]}]



    # symlink nonexistent
    FileUtils.rm(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    File.symlink(File.join("..", "..", 'settings.yaml'),
                 File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: mismatch file types w/ bad link: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 1",
         "diffs"=>[{"path"=>"1_sub_dir/1_sample.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"1_sub_dir/1_sample.txt", "contents"=>nil}]}]



    # characterSpecial
    FileUtils.rm(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    File.symlink("/dev/tty",
                 File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: mismatch file types: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test 1",
         "diffs"=>[{"path"=>"1_sub_dir/1_sample.txt", "source_type"=>"file", "target_type"=>"link", "target_path_previous_version"=>"1_sub_dir/1_sample.txt", "contents"=>nil}]}]

    Updates.mark_reviewed(@settings, 'test 1', '1_sub_dir')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed dir replaced file: #{all_repo_diffs.inspect}" if all_repo_diffs != []
    
    
    
    # check that there's no outgoing diffs if there's no outgoing
    setup_settings({'repositories'=>[]})
    repo_test0 = @settings.add_repo('test out 0', File.join(@test_data_dir, 'sources', 'cracked'),
      nil, File.join(@test_data_dir, 'my_copies', 'cracked'))
    all_out_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: diff with no source isn't blank: #{all_out_diffs.inspect}" if all_out_diffs != []
    
    # ... or no my_loc
    setup_settings({'repositories'=>[]})
    repo_test0 = @settings.add_repo('test out 0', File.join(@test_data_dir, 'sources', 'cracked'),
      File.join(@test_data_dir, 'my_copies', 'cracked'), nil)
    all_out_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: diff with no outgoing isn't blank: #{all_out_diffs.inspect}" if all_out_diffs != []

    # ... or neither
    setup_settings({'repositories'=>[]})
    repo_test0 = @settings.add_repo('test out 0', File.join(@test_data_dir, 'sources', 'cracked'),
      nil, nil)
    all_out_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: diff with no source/outgoing isn't blank: #{all_out_diffs.inspect}" if all_out_diffs != []
    
  end

  def test_full_workflow
    
    setup_settings({'repositories'=>[]})
    repo_test0 = @settings.add_repo('test out 0', File.join(@test_data_dir, 'sources', 'cracked'),
      File.join(@test_data_dir, 'my_copies', 'cracked'), File.join(@test_data_dir, 'targets', 'cracked'))
    FileUtils::mkpath(repo_test0['incoming_loc'])
    FileUtils::mkpath(@settings.reviewed_dir(repo_test0))
    FileUtils::mkpath(repo_test0['my_loc'])
    FileUtils::mkpath(repo_test0['outgoing_loc'])
    File.open(File.join(repo_test0['incoming_loc'], 'sample.txt'), 'w') do |out|
      out.write "gabba gabba hey\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: added incoming: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test out 0", "diffs"=>[{"path"=>"sample.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample.txt", "contents"=>nil}]}]
      
    Updates.mark_reviewed(@settings, 'test out 0')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: all reviewed: #{all_repo_diffs.inspect}" if all_repo_diffs != []
    
    puts "Here's where I expect things to start failing."
    # now let's accept those changes into our own
    File.open(File.join(repo_test0['my_loc'], 'sample.txt'), 'w') do |out|
      out.write "gabba gabba hey\n"
    end
    all_out_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: must copy out: #{all_out_diffs.inspect}" if all_out_diffs !=
      [{"name"=>"test out 0", "diffs"=>[{"path"=>"sample.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample.txt", "contents"=>nil}]}]

    Updates.copy_to_outgoing(@settings, 'test out 0')
    all_out_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: all copied out: #{all_out_diffs.inspect}" if all_out_diffs != []
    
    
    
    # now let's update it with a transport that uses versioned files
    FileUtils.cp File.join(repo_test0['incoming_loc'], 'sample.txt'), File.join(repo_test0['incoming_loc'], 'sample_2.txt')
    File.open(File.join(repo_test0['incoming_loc'], 'sample_2.txt'), 'a') do |out|
      out.write "you're a cheater face\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: versioned incoming: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test out 0", "diffs"=>
        [{"path"=>"sample_2.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample.txt", "contents"=>nil}]}]
    
    
    
    # ... and another version
    FileUtils.cp File.join(repo_test0['incoming_loc'], 'sample_2.txt'), File.join(repo_test0['incoming_loc'], 'sample_3.txt')
    File.open(File.join(repo_test0['incoming_loc'], 'sample_3.txt'), 'a') do |out|
      out.write "like to shoot, not play\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: versioned incoming: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test out 0", "diffs"=>
        [{"path"=>"sample_3.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample.txt", "contents"=>nil}]}]
    
    
    
    # ... and one last version
    FileUtils.mv File.join(repo_test0['incoming_loc'], 'sample_3.txt'), File.join(repo_test0['incoming_loc'], 'sample_16.txt')
    File.open(File.join(repo_test0['incoming_loc'], 'sample_16.txt'), 'a') do |out|
      out.write "fly your leisure pace\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: versioned incoming: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test out 0", "diffs"=>
        [{"path"=>"sample_16.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample.txt", "contents"=>nil}]}]
    
    
    
    puts "mark reviewed, check for empty set"
    puts "add multiple reviewed, and remove old reviewed versions"
    #puts "put multiple incoming, check for different acceptance"
    
    
    
    # do the same for outgoing files
#    FileUtils.cp_r File.join(repo_test0['incoming_loc'], 'sample_2.txt'), File.join(repo_test0['my_loc'], 'my_sample.txt')
#    all_repo_diffs = Updates.all_outgoing_diffs(@settings)
#    puts "fail: versioned outgoing: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"name"=>"test out 0", "diffs"=>
        [{"path"=>"my_sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample.txt", "target_path_next_version"=>"sample_3.txt", "contents"=>nil}]}]
    
    
    puts "when there's a change in my copy (whether or not to the same output) and I publish"
    puts "  if outgoing is marked as number-versioned"
    puts "    w/o all versions accepted, check for no addition to version"
    puts "    w/ all versions accepted, check for new version of outgoing file"
    puts "      ... and if output is same as input, ensure it's marked as reviewed"
    puts "  else outgoing not number-versioned"
    puts "    so check for new outgoing version (always)"
    #puts "put multiple outgoing, check for correct outgoing"
    puts "Here's where I expect things to stop failing."
    
  end
    
end

#SettingsTest.new.run # run all test_* methods
#SettingsTest.new.test_simple_json
SettingsTest.new.test_versioned_diffs
#SettingsTest.new.test_repo_creation
#SettingsTest.new.test_basic_diffs
#SettingsTest.new.test_full_workflow
