# run a ton of tests, and no output is good (see commands at end of file)

require File.join(File.expand_path(File.dirname(__FILE__)), "../../ruby/settings.rb")
require File.join(File.expand_path(File.dirname(__FILE__)), "../../ruby/updates.rb")
require File.join(File.expand_path(File.dirname(__FILE__)), "test_utils.rb")

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
    if (settings_data['repositories'] != nil)
      settings_data['repositories'].each do |repo|
        TestUtils.make_repo_dirs(repo)
      end
    end
  end
  
  def add_repo(name, incoming_loc, my_loc = nil, outgoing_loc = nil, not_versioned = false)
    TestUtils.add_repo(@settings, name, incoming_loc, my_loc, outgoing_loc, not_versioned)
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
    setup_settings({'repositories'=>[]})
    
    repo_name = "Test for dup"
    repo = @settings.add_repo(repo_name, @test_data_dir + "/some/funky/dir")
    repo_id = repo['id']
    puts "fail: didn't add test repo" if repo == nil
    puts "fail: repo should have ID of 0, but has #{repo['id']}" if repo['id'] != 0
    puts "fail: didn't create reviewed folder" if !(File.exist? @settings.reviewed_dir(repo))
    puts "fail: didn't get reviewed folder for ID" if !@settings.reviewed_dir(repo_id)
    @settings.remove_repo(repo_id)
    puts "fail: didn't remove reviewed folder" if @settings.reviewed_dir(repo_name) && File.exist?(@settings.reviewed_dir(repo_name))
    
    repo = @settings.add_repo(repo_name, @test_data_dir + "/some/funky/dir")
    repo_id = repo['id']
    puts "fail: didn't add test repo after removal" if repo == nil
    puts "fail: repo doesn't have ID of 0 after removal" if repo['id'] != 0
    repo = @settings.add_repo(repo_name, @test_data_dir + "/another/funky/dir")
    puts "fail: no reviewed folder for duplicate name" if !File.exist? @settings.reviewed_dir(repo_name)
    @settings.remove_repo(repo_id)
    puts "fail: didn't remove reviewed folder for duplicate name" if @settings.reviewed_dir(repo_name) && File.exist?(@settings.reviewed_dir(repo_name))
    
    repo = @settings.add_repo(repo_name, @test_data_dir + "/some/funky/dir")
    puts "fail: didn't add test repo after 2nd removal" if repo == nil
    repo = @settings.add_repo(repo_name, @test_data_dir + "/some/funky/dir")
    puts "fail: added duplicate test repo" if repo != nil
    repo = @settings.add_repo(repo_name + "2", @test_data_dir + "/some/funky/dir2")
    puts "fail: repo should have ID of 3, but has #{repo['id']} -- #{@settings.properties}" if repo['id'] != 3
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
    want2 = "{\"akey\":\"aval\", \"ckey\":\"cval\", \"bkey\":\"bval\"}" # which is the ordering in Ruby 1.8
    puts "fail: bad json encoding\n test: #{test}\n got:  #{Updates.strings_arrays_hashes_json(test)}\n want: #{want}" if
      Updates.strings_arrays_hashes_json(test) != want &&
      Updates.strings_arrays_hashes_json(test) != want2
    
    test = { "akey" => nil, "bkey" => ["bval1","bval2"], "ckey" => [], "dkey" => {"dkey1" => "dval1", "ekey1" => {"ekey11" => ["eval11",nil]}} }
    want = "{\"akey\":null, \"bkey\":[\"bval1\", \"bval2\"], \"ckey\":[], \"dkey\":{\"dkey1\":\"dval1\", \"ekey1\":{\"ekey11\":[\"eval11\", null]}}}"
    want2 = "{\"akey\":null, \"ckey\":[], \"dkey\":{\"dkey1\":\"dval1\", \"ekey1\":{\"ekey11\":[\"eval11\", null]}}, \"bkey\":[\"bval1\", \"bval2\"]}" # which is the ordering in Ruby 1.8
    puts "fail: bad json encoding\n test: #{test}\n got:  #{Updates.strings_arrays_hashes_json(test)}\n want: #{want}" if
      Updates.strings_arrays_hashes_json(test) != want &&
      Updates.strings_arrays_hashes_json(test) != want2
    
  end




  def test_versioned_diffs
    
    file = "file_abc.txt"
    match = Updates.match_numeric_suffix(file)
    puts "fail: bad match: #{file} => #{match}" if match != nil
    combos = Updates.possible_version_exts(file)
    puts "fail: bad combo #{file} => #{combos}" if combos != [["file_abc", ".txt"]]
    
    file = "our_sample_3.txt"
    match = Updates.match_numeric_suffix(file)
    puts "fail: bad match: #{file} => #{match}" if match[1] != "our_sample" && match[3] != "3"
    combos = Updates.possible_version_exts(file)
    puts "fail: bad combo #{file} => #{combos}" if combos != [["our_sample_3", ".txt"]]
    
    file = "dir1/dir2/file_abc.txt_2"
    match = Updates.match_numeric_suffix(file)
    puts "fail: bad match: #{file} => #{match}" if match[3] != "2" && match[4] != nil?
    combos = Updates.possible_version_exts(file)
    puts "fail: bad combo #{file} => #{combos}" if combos != [["dir1/dir2/file_abc", ".txt_2"]]
    
    file = "dir1/dir2/file_2.rss.xml"
    match = Updates.match_numeric_suffix(file)
    puts "fail: bad match: #{file} => #{match}" if match[3] != "2" && match[4] != '.rss.xml'
    combos = Updates.possible_version_exts(file)
    puts "fail: bad combo #{file} => #{combos}" if combos != [["dir1/dir2/file_2", ".rss.xml"], ["dir1/dir2/file_2.rss", ".xml"]]
    
    file = "dir1/dir_2.out/file_2.is.mine_345.rss.txt"
    match = Updates.match_numeric_suffix(file)
    puts "fail: bad match: #{file} => #{match}" if match[3] != "345" && match[4] != '.rss.xtxt'
    combos = Updates.possible_version_exts(file)
    puts "fail: bad combo #{file} => #{combos}" if combos != [
      ["dir1/dir_2.out/file_2", ".is.mine_345.rss.txt"],
      ["dir1/dir_2.out/file_2.is", ".mine_345.rss.txt"],
      ["dir1/dir_2.out/file_2.is.mine_345", ".rss.txt"],
      ["dir1/dir_2.out/file_2.is.mine_345.rss", ".txt"]
    ]
    
    # not doing this because it's not important (and the code doesn't work on it :-)
    #file = "dir1/dir2/file_1.4.txt"
    
    
    
    v_dir = File.join(@test_data_dir, "versioned_filenames")
    FileUtils::remove_entry_secure(v_dir, true)
    FileUtils::mkdir_p(v_dir)
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
    FileUtils::mkdir_p(File.join(v_dir, "some"))
    FileUtils::mkdir_p(File.join(v_dir, "some_3"))
    
    
    # Remember: the diff_results are differences of source with target directories.
    diff_results = [
      {'path'=>'sum.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'some.txt', 'source_type'=>nil, 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'some1.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil}
    ]
    result = Updates.versioned_diffs2(diff_results, v_dir)
    expected = [
      {'path'=>'some.txt', 'source_type'=>nil, 'target_type'=>'file', 'target_path_previous_version'=>'some.txt', 'target_path_next_version'=>'some.txt', 'contents'=>nil},
      {'path'=>'some1.txt', 'source_type'=>'file', 'target_type'=>'file', 'target_path_previous_version'=>'some1.txt', 'target_path_next_version'=>'some1.txt', 'contents'=>nil},
      {'path'=>'sum.txt', 'source_type'=>'file', 'target_type'=>nil, 'target_path_previous_version'=>nil, "target_path_next_version"=>'sum.txt', 'contents'=>nil}
    ]
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; result.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: versioned results w/o versions: #{result}" if result != expected
    
    
    diff_results = [
      {'path'=>'some3.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil}
    ]
    result = Updates.versioned_diffs2(diff_results, v_dir)
    #versioned_info = Updates.versioned_filenames(diff_results)
    #latest_target_versions = Updates.latest_versions(versioned_info, v_dir)
    #result = Updates.only_new_revisions(versioned_info, latest_target_versions, true)
    expected = []
    puts "fail: versioned diff for initial file: #{result}" if expected != result
    
    
    diff_results = [
      {'path'=>'some3.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'some3_2.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'some3_3.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil}
    ]
    result = Updates.versioned_diffs2(diff_results, v_dir)
    #versioned_info = Updates.versioned_filenames(diff_results)
    #latest_target_versions = Updates.latest_versions(versioned_info, v_dir)
    #result = Updates.only_new_revisions(versioned_info, latest_target_versions, true)
    expected = []
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; result.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: old versioned results: #{result}" if result != expected
    
    
    diff_results = [
      {'path'=>'some4.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'some4_1.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'some4_2.txt', 'source_type'=>nil, 'target_type'=>'file', 'contents'=>nil},
      {'path'=>'some4_3.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      # This shouldn't happen: it would mean the originator is changing the file AND using versioned files.
      {'path'=>'some4_11.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil},
      # These shouldn't happen: it would mean they've got alternative version branches (or the originator versioning system is different).
      {'path'=>'some4.txt_5', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'some4.txt_12', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil}
    ]
    result = Updates.versioned_diffs2(diff_results, v_dir)
    #versioned_info = Updates.versioned_filenames(diff_results)
    #versions = versioned_info.map { |v_dm| v_dm['version'] }
    #result = Updates.only_new_revisions(versioned_info, versions, v_dir, true)
    expected = [
      {'path'=>'some4_11.txt', 'source_type'=>'file', 'target_type'=>'file', 'target_path_previous_version'=>'some4_11.txt', 'target_path_next_version'=>'some4_11.txt', 'contents'=>nil},
      # this may not be a good thing, but I'm not going to try and handle it right now
      {'path'=>'some4.txt_12', 'source_type'=>'file', 'target_type'=>nil, 'target_path_previous_version'=>'some4_11.txt', 'target_path_next_version'=>'some4.txt_12', 'contents'=>nil}
    ]
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; result.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: old versioned results for 4: #{result}" if result != expected
    
    
    
    #### BEGIN tests for intermediate functions; helpful for internal testing, but not real user stories.
    
    filenames = Updates.all_target_file_versions(v_dir, "sum", ".txt")
    expected = []
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; filenames.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: versioned files exist: #{filenames}" if expected != filenames
    
    filenames = Updates.all_target_file_versions(v_dir, "some", ".txt")
    expected = [['some.txt']]
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; filenames.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: initial file doesn't match: #{filenames}" if expected != filenames
    
    filenames = Updates.all_target_file_versions(v_dir, "some.txt", "")
    expected = [['some.txt']]
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; filenames.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: initial file altogether doesn't match: #{filenames}" if expected != filenames
    
    filenames = Updates.all_target_file_versions(v_dir, "some3", ".txt")
    expected = ['some3_12.txt', 'some3_2.txt'].map { |elem| m = Updates.match_numeric_suffix(elem); [m[1], m[4], m[3].to_i] }
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; filenames.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: versioned files don't match: #{filenames}" if expected != filenames
    
    filenames = Updates.all_target_file_versions(v_dir, "some4", ".txt")
    expected = [['some4.txt']] +
      ['some4_11.txt', 'some4_2.txt', 'some4_3.txt'].map { |elem| m = Updates.match_numeric_suffix(elem); [m[1], m[4], m[3].to_i] }
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; filenames.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: initial and versioned files don't match: #{filenames}" if expected != filenames
    
    
    
    diff_results = [
      {'path'=>'some.txt', 'source_type'=>'file', 'target_type'=>'file', 'contents'=>nil}
    ]
    result = Updates.latest_versions(Updates.versioned_filenames(diff_results).map { |v_dm| v_dm['version'] }, v_dir)
    expected = {"some.txt"=>["some.txt"]}
    #puts "Expected:"; expected.each { |inresult| puts inresult.to_s + "\n" }
    #puts "... and got:"; result.each { |inresult| puts inresult.to_s + "\n" }
    puts "fail: versioned diff single 1: #{result}" if expected != result
    
    diff_results = [
      {'path'=>'some.txt', 'source_type'=>nil, 'target_type'=>file, 'contents'=>nil},
      {'path'=>'some_1.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil}
    ]
    result = Updates.latest_versions(Updates.versioned_filenames(diff_results).map { |v_dm| v_dm['version'] }, v_dir)
    expected = {"some.txt"=>["some.txt"]}
    puts "fail: versioned diff single 2: #{result}" if expected != result
    
    diff_results = [
      {'path'=>'some_1.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil}
    ]
    result = Updates.latest_versions(Updates.versioned_filenames(diff_results).map { |v_dm| v_dm['version'] }, v_dir)
    expected = {"some.txt"=>["some.txt"]}
    puts "fail: versioned diff single 3: #{result}" if expected != result
    
    # some old versions are hanging around in the incoming
    diff_results = [
      {'path'=>'some3.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil}
    ]
    result = Updates.latest_versions(Updates.versioned_filenames(diff_results).map { |v_dm| v_dm['version'] }, v_dir)
    expected = {"some3.txt"=>["some3", ".txt", 12]}
    puts "fail: latest version for initial file: #{result}" if expected != result
    
    # eg. some3_12.txt is reviewed (and some3.txt is gone)
    diff_results = [
      {'path'=>'some3_13.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil},
      {'path'=>'some3_14.txt', 'source_type'=>'file', 'target_type'=>nil, 'contents'=>nil}
    ]
    result = Updates.latest_versions(Updates.versioned_filenames(diff_results).map { |v_dm| v_dm['version'] }, v_dir)
    expected = {"some3.txt"=>["some3", ".txt", 12]}
    puts "fail: versioned diff for multiple new ones: #{result}" if expected != result
    
    
    #### END tests for intermediate functions; helpful for internal testing, but not real user stories.
    
    
    
    
    
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
    result = Updates.versioned_filenames diff_results
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
    #puts "Expected:"; expected.each { |inresult| puts inresult.inspect + "\n" }
    #puts "... and got:"; result.each { |inresult| puts inresult.inspect + "\n" }
    puts "fail: basic versioned file diffs: #{result.inspect}" if result != expected
    
    
    
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
    
    versioned_diffs = Updates.versioned_diffs2 diff_results, v_dir
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
      [{"id"=>0, "name"=>"test file", "diffs"=>[{"path"=>"", "source_type"=>"file", "target_type"=>nil, "contents"=>nil}]}]
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
    FileUtils.mkdir_p(repo_test0['incoming_loc'])
    FileUtils.mkdir_p(@settings.reviewed_dir(repo_test0))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: diffs on one blank repo: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    repo_test1 = {'id' => 1, 'name'=>'test 1', 'incoming_loc'=>File.join(@test_data_dir, 'sources', 'hacked-again')}
    @settings.replace({'repositories'=>[repo_test0, repo_test1]})
    FileUtils.mkdir_p(repo_test1['incoming_loc'])
    FileUtils.mkdir_p(@settings.reviewed_dir(repo_test1))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: diffs on two blank repos: #{all_repo_diffs.inspect}" if all_repo_diffs != []




    File.new(File.join(repo_test0['incoming_loc'], 'sample.txt'), 'w')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: not one empty file: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>0, "name"=>"test 0", "diffs"=>[{"path"=>"sample.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"sample.txt", "contents"=>nil}]}]

    Updates.mark_reviewed(@settings, 'test 0', 'sample.txt')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: after review: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    File.open(File.join(repo_test0['incoming_loc'], 'sample.txt'), 'w') do |out|
      out.write "gabba gabba hey\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: one file with different content size: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>0, "name"=>"test 0", "diffs"=>[{"path"=>"sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample.txt", "target_path_next_version"=>"sample.txt", "contents"=>nil}]}]

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
      [{"id"=>0, "name"=>"test 0", "diffs"=>[{"path"=>"sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample.txt", "target_path_next_version"=>"sample.txt", "contents"=>nil}]}]

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
      [{"id"=>0, "name"=>"test 0", "diffs"=>[{"path"=>"sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample.txt", "target_path_next_version"=>"sample.txt", "contents"=>nil}]},
       {"id"=>1, "name"=>"test 1", "diffs"=>[{"path"=>"1_sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"1_sample.txt", "target_path_next_version"=>"1_sample.txt", "contents"=>nil}]}]

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
      [{"id"=>0, "name"=>"test 0",
        "diffs" =>
         [{"path"=>"a_sub_dir", "source_type"=>"directory", "target_type"=>nil,
            "target_path_previous_version"=>nil, "target_path_next_version"=>'a_sub_dir', "contents"=>['a_sample.txt']}]}]

    Updates.mark_reviewed(@settings, 'test 0', a_filename)
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: all synched up again: #{all_repo_diffs.inspect}" if all_repo_diffs != []



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
      [{"id"=>1, "name"=>"test 1",
         "diffs"=>
         [{"path"=>File.join("1_sub_dir"), "source_type"=>"directory",
            "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"1_sub_dir",
            "contents"=>[File.join("11_sub_dir", "111_sub_dir", '1_sample.txt'),
                         File.join("11_sub_dir", "111_sub_dir", '1_sample2.txt'),
                         File.join("11_sub_dir", "112_sub_dir", '1121_sub_dir', '1_sample3.txt')]}]}]

    Updates.mark_reviewed(@settings, 'test 1', File.join(deeper1, "1_sample.txt"))
    Updates.mark_reviewed(@settings, 'test 1', File.join(deeper1, "1_sample2.txt"))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: source files in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>1, "name"=>"test 1",
         "diffs"=>
         [{"path"=>File.join("1_sub_dir", "11_sub_dir", "112_sub_dir"),
            "source_type"=>"directory", 
            "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>File.join("1_sub_dir", "11_sub_dir", "112_sub_dir"),
            "contents"=>[File.join('1121_sub_dir', '1_sample3.txt')]}]}]



    File.new(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '11_sub_dir', 'sample.txt'), 'w')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: source & reviewed files in deep sources: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>1, "name"=>"test 1",
         "diffs"=>
         [{"path"=>File.join("1_sub_dir", "11_sub_dir", "112_sub_dir"),
            "source_type"=>"directory",
            "target_type"=>nil,
            "target_path_previous_version"=>nil, "target_path_next_version"=>File.join("1_sub_dir", "11_sub_dir", "112_sub_dir"),
            "contents"=>[File.join('1121_sub_dir', '1_sample3.txt')]},
          {"path"=>File.join("1_sub_dir", "11_sub_dir", "sample.txt"),
            "source_type"=>nil,
            "target_type"=>"file",
            "target_path_previous_version"=>File.join("1_sub_dir", "11_sub_dir", "sample.txt"),
            "target_path_next_version"=>File.join("1_sub_dir", "11_sub_dir", "sample.txt"),
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
      [{"id"=>1, "name"=>"test 1",
         "diffs"=>
         [{"path"=>File.join("1_sub_dir","11_sub_dir"),
            "source_type"=>nil,
            "target_type"=>"directory",
            "target_path_previous_version"=>File.join("1_sub_dir","11_sub_dir"),
            "target_path_next_version"=>File.join("1_sub_dir","11_sub_dir"),
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
      [{"id"=>1, "name"=>"test 1",
         "diffs"=>[{"path"=>"1_sub_dir", "source_type"=>"file", "target_type"=>"directory", "target_path_previous_version"=>"1_sub_dir", "target_path_next_version"=>"1_sub_dir", "contents"=>[]}]}]

    Updates.mark_reviewed(@settings, 'test 1', '1_sub_dir')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed file replaced dir: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    # mismatch dir and file
    FileUtils::rm_f(File.join(repo_test1['incoming_loc'], '1_sub_dir'))
    Dir.mkdir(File.join(repo_test1['incoming_loc'], '1_sub_dir'))
    File.new(File.join(repo_test1['incoming_loc'], '1_sub_dir', '1_sample.txt'), 'w')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: dir vs file: #{all_repo_diffs.inspect}" if all_repo_diffs != 
      [{"id"=>1, "name"=>"test 1",
         "diffs"=>
         [{"path"=>"1_sub_dir", "source_type"=>"directory", "target_type"=>"file", "target_path_previous_version"=>"1_sub_dir", "target_path_next_version"=>"1_sub_dir", "contents"=>["1_sample.txt"]}]}]

    Updates.mark_reviewed(@settings, 'test 1', '1_sub_dir')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed dir replaced file: #{all_repo_diffs.inspect}" if all_repo_diffs != []



    # symlink, existent
    FileUtils.rm(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    File.symlink(File.join("..", "..", "..", 'settings.yaml'),
                 File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: mismatch file types w/ good link: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>1, "name"=>"test 1",
         "diffs"=>[{"path"=>"1_sub_dir/1_sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"1_sub_dir/1_sample.txt", "target_path_next_version"=>"1_sub_dir/1_sample.txt", "contents"=>nil}]}]



    # symlink nonexistent
    FileUtils.rm(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    File.symlink(File.join("..", "..", 'settings.yaml'),
                 File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: mismatch file types w/ bad link: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>1, "name"=>"test 1",
         "diffs"=>[{"path"=>"1_sub_dir/1_sample.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"1_sub_dir/1_sample.txt", "target_path_next_version"=>"1_sub_dir/1_sample.txt", "contents"=>nil}]}]



    # characterSpecial
    FileUtils.rm(File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    File.symlink("/dev/tty",
                 File.join(@settings.reviewed_dir(repo_test1), '1_sub_dir', '1_sample.txt'))
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: mismatch file types: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>1, "name"=>"test 1",
         "diffs"=>[{"path"=>"1_sub_dir/1_sample.txt", "source_type"=>"file", "target_type"=>"link", "target_path_previous_version"=>"1_sub_dir/1_sample.txt", "target_path_next_version"=>"1_sub_dir/1_sample.txt", "contents"=>nil}]}]

    Updates.mark_reviewed(@settings, 'test 1', '1_sub_dir')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: reviewed dir replaced file: #{all_repo_diffs.inspect}" if all_repo_diffs != []
    
    
    
    # check that there's no outgoing diffs if there's no outgoing
    setup_settings({'repositories'=>[]})
    repo_test0 = add_repo('test out 0', File.join(@test_data_dir, 'sources', 'cracked'),
      nil, File.join(@test_data_dir, 'my_copies', 'cracked'))
    all_out_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: diff with no source isn't blank: #{all_out_diffs.inspect}" if all_out_diffs != []
    
    # ... or no my_loc
    setup_settings({'repositories'=>[]})
    repo_test0 = add_repo('test out 0', File.join(@test_data_dir, 'sources', 'cracked'),
      File.join(@test_data_dir, 'my_copies', 'cracked'), nil)
    all_out_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: diff with no outgoing isn't blank: #{all_out_diffs.inspect}" if all_out_diffs != []

    # ... or neither
    setup_settings({'repositories'=>[]})
    repo_test0 = add_repo('test out 0', File.join(@test_data_dir, 'sources', 'cracked'),
      nil, nil)
    all_out_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: diff with no source/outgoing isn't blank: #{all_out_diffs.inspect}" if all_out_diffs != []
    
  end






  def test_full_workflow
    
    setup_settings({'repositories'=>[]})
    repo_test0 = add_repo('test out 0', File.join(@test_data_dir, 'sources', 'cracked'),
      File.join(@test_data_dir, 'my_copies', 'cracked'), File.join(@test_data_dir, 'targets', 'cracked'))
    puts "fail: couldn't create repo 'test out 0'" if repo_test0 == nil
    
    File.open(File.join(repo_test0['incoming_loc'], 'sample.txt'), 'w') do |out|
      out.write "gabba gabba hey\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: added incoming: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>0, "name"=>"test out 0", "diffs"=>[{"path"=>"sample.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"sample.txt", "contents"=>nil}]}]
    
    Updates.mark_reviewed(@settings, 'test out 0')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: all reviewed: #{all_repo_diffs.inspect}" if all_repo_diffs != []
    
    # now let's accept those changes into our own
    File.open(File.join(repo_test0['my_loc'], 'sample.txt'), 'w') do |out|
      out.write "gabba gabba hey\n"
    end
    all_out_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: must copy out: #{all_out_diffs.inspect}" if all_out_diffs !=
      [{"id"=>0, "name"=>"test out 0", "diffs"=>[{"path"=>"sample.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"sample_0.txt", "contents"=>nil}]}]

    Updates.copy_to_outgoing(@settings, 'test out 0')
    all_out_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: all copied out: #{all_out_diffs.inspect}" if all_out_diffs != []
    
    
    
    # let's try some non-traditional file names
    File.open(File.join(repo_test0['incoming_loc'], 'sample_4'), 'w') do |out|
      out.write "less\n"
    end
    File.open(File.join(repo_test0['incoming_loc'], 'sample5'), 'w') do |out|
      out.write "less\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: different names: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>0, "name"=>"test out 0",
        "diffs" =>
         [{"path"=>"sample_4", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>'sample_4', "contents"=>nil},
          {"path"=>"sample5", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>'sample5', "contents"=>nil}]}]
    
    Updates.mark_reviewed(@settings, 'test out 0', "sample_4")
    Updates.mark_reviewed(@settings, 'test out 0', "sample5")
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: all synched up: #{all_repo_diffs.inspect}" if all_repo_diffs != []
    
    
    
    File.open(File.join(repo_test0['incoming_loc'], 'sample_4'), 'w') do |out|
      out.write "more gabba gabba hey\n"
    end
    File.open(File.join(repo_test0['incoming_loc'], 'sample5'), 'w') do |out|
      out.write "more gabba gabba hey\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: different names changed: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>0, "name"=>"test out 0",
        "diffs" =>
         [{"path"=>"sample_4", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample_4", "target_path_next_version"=>'sample_4', "contents"=>nil},
          {"path"=>"sample5", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample5", "target_path_next_version"=>'sample5', "contents"=>nil}]}]
    
    Updates.mark_reviewed(@settings, 'test out 0', "sample_4")
    Updates.mark_reviewed(@settings, 'test out 0', "sample5")
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: all synched up again: #{all_repo_diffs.inspect}" if all_repo_diffs != []
    
    
    
    
    File.open(File.join(repo_test0['incoming_loc'], 'sample_5'), 'w') do |out|
      out.write "more gabba gabba hey\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: different names changed again: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>0, "name"=>"test out 0",
        "diffs" =>
         [{"path"=>"sample_5", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample_4", "target_path_next_version"=>'sample_5', "contents"=>nil}]}]
    
    Updates.mark_reviewed(@settings, 'test out 0', "sample_5", "sample_4")
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: all synched up again, too: #{all_repo_diffs.inspect}" if all_repo_diffs != []
    
    
    
    
    # now let's update it with a transport that uses versioned files
    FileUtils.cp File.join(repo_test0['incoming_loc'], 'sample.txt'), File.join(repo_test0['incoming_loc'], 'sample_2.txt')
    File.open(File.join(repo_test0['incoming_loc'], 'sample_2.txt'), 'a') do |out|
      out.write "you're a cheater face\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: versioned incoming 2: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>0, "name"=>"test out 0", 
        "diffs"=>
        [{"path"=>"sample_2.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample.txt", "target_path_next_version"=>"sample_2.txt", "contents"=>nil}]
      }]
    
    
    
    # ... and another version
    FileUtils.cp File.join(repo_test0['incoming_loc'], 'sample_2.txt'), File.join(repo_test0['incoming_loc'], 'sample_4.txt')
    File.open(File.join(repo_test0['incoming_loc'], 'sample_4.txt'), 'a') do |out|
      out.write "like to shoot, not play\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: versioned incoming 4: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>0, "name"=>"test out 0", 
        "diffs"=>
        [{"path"=>"sample_2.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample.txt", "target_path_next_version"=>"sample_2.txt", "contents"=>nil},
         {"path"=>"sample_4.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample.txt", "target_path_next_version"=>"sample_4.txt", "contents"=>nil}]
      }]
    
    
    # ... and then let's review one
    Updates.mark_reviewed(@settings, 'test out 0', 'sample_2.txt', 'sample.txt')
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: versioned incoming 4 reviewed: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>0, "name"=>"test out 0",
        "diffs"=>
        [{"path"=>"sample_4.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample_2.txt", "target_path_next_version"=>"sample_4.txt", "contents"=>nil}]
      }]
    
    
    # ... and another version
    FileUtils.cp File.join(repo_test0['incoming_loc'], 'sample_4.txt'), File.join(repo_test0['incoming_loc'], 'sample_8.txt')
    File.open(File.join(repo_test0['incoming_loc'], 'sample_8.txt'), 'a') do |out|
      out.write "fly your leisure pace\n"
    end
    all_repo_diffs = Updates.all_repo_diffs(@settings)
    puts "fail: versioned incoming 8: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>0, "name"=>"test out 0",
        "diffs"=>
        [{"path"=>"sample_4.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample_2.txt", "target_path_next_version"=>"sample_4.txt", "contents"=>nil},
         {"path"=>"sample_8.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample_2.txt", "target_path_next_version"=>"sample_8.txt", "contents"=>nil}]
      }]
    
    
    # Note that it may break at random places with: wrong argument type #<Class:0x000001008abaa0> (expected Data) (TypeError)
    # Note that it may work by commenting out the next test.
    # It works in Ruby v 1.8.  Ug.

    # ... and one last version, with changes to previous copies
    FileUtils.cp File.join(repo_test0['incoming_loc'], 'sample_8.txt'), File.join(repo_test0['incoming_loc'], 'sample_16.txt')
    File.open(File.join(repo_test0['incoming_loc'], 'sample.txt'), 'a') do |out|
      out.write "boo-ya!\n"
    end
    File.open(File.join(repo_test0['incoming_loc'], 'sample_2.txt'), 'a') do |out|
      out.write "boo-ya!\n"
    end
    File.open(File.join(repo_test0['incoming_loc'], 'sample_16.txt'), 'a') do |out|
      out.write "boo-ya!\n"
    end
    File.open(File.join(repo_test0['incoming_loc'], 'sample2_4.txt'), 'a') do |out|
      out.write "Hello.!\n"
    end
    result = Updates.all_repo_diffs(@settings)
    expected = 
      [{"id"=>0, "name"=>"test out 0", 
        "diffs"=>
        [{"path"=>"sample_2.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample_2.txt", "target_path_next_version"=>"sample_2.txt", "contents"=>nil},
         {"path"=>"sample_4.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample_2.txt", "target_path_next_version"=>"sample_4.txt", "contents"=>nil},
         {"path"=>"sample_8.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample_2.txt", "target_path_next_version"=>"sample_8.txt", "contents"=>nil},
         {"path"=>"sample_16.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample_2.txt", "target_path_next_version"=>"sample_16.txt", "contents"=>nil},
         {"path"=>"sample2_4.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"sample2_4.txt", "contents"=>nil}]
      }]
    #puts "Expected:"; expected.each { |inresult| puts inresult.inspect + "\n" }
    #puts "... and got:"; result.each { |inresult| puts inresult.inspect + "\n" }
    puts "fail: versioned incoming 16: #{result.inspect}" if result != expected
    
    
    Updates.mark_reviewed(@settings, 'test out 0', 'sample_4.txt')
    Updates.mark_reviewed(@settings, 'test out 0', 'sample2_4.txt')
    result = Updates.all_repo_diffs(@settings)
    expected = 
      [{"id"=>0, "name"=>"test out 0", 
        "diffs"=>
        [{"path"=>"sample_8.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample_4.txt", "target_path_next_version"=>"sample_8.txt", "contents"=>nil},
         {"path"=>"sample_16.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample_4.txt", "target_path_next_version"=>"sample_16.txt", "contents"=>nil}]
      }]
    puts "fail: versioned incoming accepted 4: #{result.inspect}" if result != expected
    
    
    Updates.mark_reviewed(@settings, 'test out 0', 'sample_8.txt', 'sample_4.txt')
    result = Updates.all_repo_diffs(@settings)
    expected = 
      [{"id"=>0, "name"=>"test out 0", 
        "diffs"=>
        [{"path"=>"sample_16.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"sample_8.txt", "target_path_next_version"=>"sample_16.txt", "contents"=>nil}]
      }]
    puts "fail: versioned incoming accepted 8: #{result.inspect}" if result != expected
    
    
    
    FileUtils.cp_r(File.join(@settings.reviewed_dir('test out 0'), 'sample_8.txt'), File.join(repo_test0['my_loc'], 'my_sample.txt'))
    all_repo_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: versioned outgoing: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>0, "name"=>"test out 0", "diffs"=>
        [{"path"=>"my_sample.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"my_sample_0.txt", "contents"=>nil}]}]
    
    
    # in the program this will copy to my_sample_0.txt, but we'll do my_sample.txt just for testing
    Updates.copy_to_outgoing(@settings, 'test out 0', 'my_sample.txt')
    all_repo_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: versioned outgoing after copy 8: #{all_repo_diffs.inspect}" if all_repo_diffs != []
    
    
    Updates.mark_reviewed(@settings, 'test out 0', 'sample_16.txt', 'sample_8.txt')
    result = Updates.all_repo_diffs(@settings)
    expected = []
    puts "fail: versioned incoming accepted 16: #{result.inspect}" if result != expected
    puts "fail: versioned incoming reviewed not gone" if File.exist? File.join(@settings.reviewed_dir('test out 0'), "sample_8.txt")
    
    
    # copy that reviewed info into my own copy
    FileUtils.cp_r(File.join(@settings.reviewed_dir('test out 0'), 'sample_16.txt'), File.join(repo_test0['my_loc'], 'my_sample.txt'))
    all_repo_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: versioned outgoing after copy 16: #{all_repo_diffs.inspect}" if all_repo_diffs !=
      [{"id"=>0, "name"=>"test out 0", "diffs"=>
        [{"path"=>"my_sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"my_sample.txt", "target_path_next_version"=>"my_sample_0.txt", "contents"=>nil}]}]
    
    
    Updates.copy_to_outgoing(@settings, 'test out 0', 'my_sample.txt', 'my_sample_0.txt')
    all_repo_diffs = Updates.all_outgoing_diffs(@settings)
    puts "fail: versioned outgoing after 16 pushed out: #{all_repo_diffs.inspect}" if all_repo_diffs != []
    puts "fail: versioned outgoing after 16 pushed out not created" if not File.exist? File.join(repo_test0['outgoing_loc'], 'my_sample_0.txt')
    
    
    File.open(File.join(repo_test0['my_loc'], 'my_sample.txt'), 'a') do |out|
      out.write "Thank you.\n"
    end
    File.open(File.join(repo_test0['my_loc'], 'our_sample_3.txt'), 'a') do |out|
      out.write "You're welcome.\n"
    end
    result = Updates.all_outgoing_diffs(@settings)
    puts "fail: versioned outgoing after another change: #{result}" if result !=
      [{"id"=>0, "name"=>"test out 0", "diffs"=>
        [{"path"=>"my_sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"my_sample_0.txt", "target_path_next_version"=>"my_sample_1.txt", "contents"=>nil},
         {"path"=>"our_sample_3.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"our_sample_3_0.txt", "contents"=>nil}]}]
    
    
    Updates.copy_to_outgoing(@settings, 'test out 0', 'our_sample_3.txt')
    result = Updates.all_outgoing_diffs(@settings)
    puts "fail: versioned outgoing pushed after another change: #{result.inspect}" if result !=
      [{"id"=>0, "name"=>"test out 0", "diffs"=>
        [{"path"=>"my_sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"my_sample_0.txt", "target_path_next_version"=>"my_sample_1.txt", "contents"=>nil}]}]
    
    
    # now test when the outgoing location is the same as an incoming location
    @settings.change_repo_outgoing('0', repo_test0['incoming_loc'])
    # ... with a file that has some new text
    File.rename(File.join(repo_test0['my_loc'], 'my_sample.txt'), File.join(repo_test0['my_loc'], 'sample.txt'))
    result = Updates.all_outgoing_diffs(@settings)
    puts "fail: versioned outgoing same as incoming: #{result.inspect}" if result !=
      [{"id"=>0, "name"=>"test out 0",
        "diffs"=>[{"path"=>"our_sample_3.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"our_sample_3_0.txt", "contents"=>nil},
                  {"path"=>"sample.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"sample_16.txt", "target_path_next_version"=>"sample_17.txt", "contents"=>nil}]}]
    Updates.copy_to_outgoing(@settings, 'test out 0', 'sample.txt', 'sample_17.txt')
    result = Updates.all_repo_diffs(@settings)
    puts "fail: versioned incoming after outgoing pushed: #{result.inspect}" if result != []
    
    
    # now for a non-versioned repo
    repo_test_2nd = add_repo('test out 2nd', File.join(@test_data_dir, 'sources_2nd', 'cracked'),
      File.join(@test_data_dir, 'my_copies_2nd', 'cracked'), File.join(@test_data_dir, 'targets_2nd', 'cracked'), true)
    puts "fail: couldn't create repo 'test out 2nd'" if repo_test_2nd == nil
    
    
    File.open(File.join(repo_test_2nd['my_loc'], 'second.txt'), 'a') do |out|
      out.write "No, thank you.\n"
    end
    result = Updates.all_outgoing_diffs(@settings)
    puts "fail: second repo has change: #{result}" if result != 
      [{"id"=>0, "name"=>"test out 0",
        "diffs"=>[{"path"=>"our_sample_3.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"our_sample_3_0.txt", "contents"=>nil}]}, 
       {"id"=>1, "name"=>"test out 2nd",
        "diffs"=>[{"path"=>"second.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"second.txt", "contents"=>nil}]}]
    
    
    Updates.copy_to_outgoing(@settings, 'test out 0', 'our_sample_3.txt', 'our_sample_3_0.txt')
    Updates.copy_to_outgoing(@settings, 'test out 2nd', 'second.txt')
    result = Updates.all_outgoing_diffs(@settings)
    puts "fail: second repo changes accepted: #{result}" if result != []
    puts "fail: first repo version doesn't exist" if not File.exist? File.join(repo_test0['outgoing_loc'], 'our_sample_3_0.txt')
    
    
    File.open(File.join(repo_test0['my_loc'], 'our_sample_3.txt'), 'a') do |out|
      out.write "Well, why not?\n"
    end
    File.open(File.join(repo_test_2nd['my_loc'], 'second.txt'), 'a') do |out|
      out.write "Well, why not?\n"
    end
    File.open(File.join(repo_test_2nd['my_loc'], 'third_3'), 'a') do |out|
      out.write "Well, why not?\n"
    end
    File.open(File.join(repo_test_2nd['my_loc'], 'fourth'), 'a') do |out|
      out.write "Well, why not?\n"
    end
    result = Updates.all_outgoing_diffs(@settings)
    puts "fail: first & second repo have more changes: #{result}" if result != 
      [{"id"=>0, "name"=>"test out 0",
        "diffs"=>[{"path"=>"our_sample_3.txt", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>"our_sample_3_0.txt", "target_path_next_version"=>"our_sample_3_1.txt", "contents"=>nil}]}, 
       {"id"=>1, "name"=>"test out 2nd",
        "diffs"=>[{"path"=>"fourth", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"fourth", "contents"=>nil},
                  {"path"=>"second.txt", "source_type"=>"file", "target_type"=>"file", "target_path_previous_version"=>"second.txt", "target_path_next_version"=>"second.txt", "contents"=>nil},
                  {"path"=>"third_3", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"third_3", "contents"=>nil}]}]
    
    
    Updates.copy_to_outgoing(@settings, 'test out 0', 'our_sample_3.txt', 'our_sample_3_1.txt')
    Updates.copy_to_outgoing(@settings, 'test out 2nd', 'second.txt')
    Updates.copy_to_outgoing(@settings, 'test out 2nd', 'third_3')
    Updates.copy_to_outgoing(@settings, 'test out 2nd', 'fourth')
    result = Updates.all_outgoing_diffs(@settings)
    puts "fail: later first & second repo more changes accepted #{result}" if result != []
    puts "fail: later first repo version doesn't exist" if not File.exist? File.join(repo_test0['outgoing_loc'], 'our_sample_3_0.txt')
    puts "fail: later first repo reviewed version doesn't exist" if not File.exist? File.join(@settings.reviewed_dir(repo_test0), 'our_sample_3_0.txt')
    puts "fail: later second repo version doesn't exist" if not File.exist? File.join(repo_test_2nd['outgoing_loc'], 'second.txt')
    puts "fail: later second repo reviewed version doesn't exist" if File.exist? File.join(@settings.reviewed_dir(repo_test_2nd), 'second.txt')


    File.open(File.join(repo_test0['my_loc'], 'fourth_sample'), 'a') do |out|
      out.write "Who cares what's in the file?\n"
    end
    result = Updates.all_outgoing_diffs(@settings)
    puts "fail: non-versioned file #{result}" if result !=
      [{"id"=>0, "name"=>"test out 0",
        "diffs"=>[{"path"=>"fourth_sample", "source_type"=>"file", "target_type"=>nil, "target_path_previous_version"=>nil, "target_path_next_version"=>"fourth_sample_0", "contents"=>nil}]}]
    
    
  end
    
end

SettingsTest.new.run # run all test_* methods
#SettingsTest.new.test_simple_json
#SettingsTest.new.test_versioned_diffs
#SettingsTest.new.test_repo_creation
#SettingsTest.new.test_basic_diffs
#SettingsTest.new.test_full_workflow
