require 'yaml'
require 'fileutils'

# command-line usage:
# 1) Uncomment the last line(s) of this file, then:
# ruby settings.rb
# 2) ... or do this:
# ruby -e 'load "settings.rb"; SEE_END_OF_FILE'

# When running in Titanium, you can print to the console ('puts' doesn't always show immediately):
#Ti.API.print("I'm here!\n")

class Settings

  VERSION = "0"
  
  @@settings_dir = ""
  # format: { 'repositories' => [ { 'id' => NUM, 'name' => 'XYZ', 'incoming_loc' => 'XYZ', 'my_loc' => 'XYZ', 'outgoing_loc' => 'XYZ', 'versioned' => false|true } ... ] }
  #   where incoming_loc / my_loc / outgoing_loc values may be nil
  # see test settings.rb for example structures
  BLANK_SETTINGS = {'repositories' => []}
  # Well, this is bogus: the static stuff isn't really static across pages; I guess it's a new Ruby environment every time.  So this caching is useless.  Must eliminate it.
  @@settings = BLANK_SETTINGS


=begin
This will set the static data for the settings.
dirname: directory name for location of settings.yaml; if nil, @@settings_dir will not be reset
settings: initial settings; if nil, @@settings will not be reset
=end
  def initialize(dirname, settings = nil)

    #puts "class: " + dirname.class.to_s
    #dirname.public_methods.sort.each{|name| puts name }
    #dirname.methods.sort.each{|name| puts name }

    if (dirname != nil)
      if (dirname.class.name == "RubyKObject") # for method results from Titanium
        @@settings_dir = dirname.toString()
      else
        @@settings_dir = dirname
      end
    end
    
    if (settings != nil)
      @@settings = settings
    end
    if (@@settings == BLANK_SETTINGS)
      if (File.exist? settings_file())
        @@settings = YAML.load_file(settings_file())
      end
      #YAML.dump(@settings)
    end

    FileUtils.mkdir_p(reviewed_base_dir())
  end

  def save()
    File.open(settings_file(), 'w') do |out|
      YAML.dump(@@settings, out)
    end
  end

  # for testing
  def replace(new_settings_data)
    @@settings = new_settings_data
    save()
  end

  def settings_file()
    File.join(@@settings_dir, "settings.yaml")
  end

  def data_dir()
    @@settings_dir
  end

  def properties()
    @@settings
  end
  
  def add_identity(file, id, name)
    if (file.class.name == "RubyKObject") # for method results from Titanium
      file = file.toString()
    end
    if (id.class.name == "RubyKObject") # for method results from Titanium
      id = id.toString()
    end
    if (name.class.name == "RubyKObject") # for method results from Titanium
      name = name.toString()
    end
    if (@@settings['identity'] == nil)
      @@settings['identity'] = []
    end
    @@settings['identity'] << {'file'=>file, 'id'=>id, 'name'=>name}
    save()
  end
  
  def add_diffable_extension(ext)
    if (ext.class.name == "RubyKObject") # for method results from Titanium
      ext = ext.toString()
    end
    if (@@settings['diffable_extensions'] == nil)
      @@settings['diffable_extensions'] = []
    end
    @@settings['diffable_extensions'] << ext if !@@settings['diffable_extensions'].include?(ext)
    save()
  end
  
  def diffable_extensions()
    @@settings['diffable_extensions']
  end
  
  def reviewed_base_dir()
    File.join(@@settings_dir, "reviewed_files")
  end
  
  # [a-zA-Z0-9_-.]
  def char_allowed_in_name(c)
    ('a' <= c && c <= 'z') ||
    ('A' <= c && c <= 'Z') ||
    ('0' <= c && c <= '9') ||
    c == '_' ||
    c == '-'
  end
  # return a name with all non-allowed characters replaced by "_"
  # because some places don't work well with funny characters
  # such as javascript IDs (where we can't have dots) and directory names
  def fixed_repo_name(name)
    name.gsub(/./){ |c| char_allowed_in_name(c) ? c : "_" }
  end
  
  # repo: if nil, return the base reviewed directory; otherwise if a full repo hash, return the reviewed directory; otherwise if a repo ID, return the reviewed directory if a matching one found; otherwise, nil 
  # Note that this is partly duplicated by Javascript change-summary.html getReviewedDir(repoId)
  def reviewed_dir(repo = nil)
    if (repo == nil)
      reviewed_base_dir
    else
      if (repo.class.name == "Fixnum")
        repo = get_repo_by_id(repo)
      end
      if (repo)
        File.join(reviewed_base_dir, repo['id'].to_s)
      else
        nil
      end
    end
  end

  def get_num_repos()
    @@settings['repositories'].length
  end

  # In Titanium, use JavaScript getRepoById (eg. in change-summary.html) instead, as it can crash on Ruby method calls like this. 
  # (It can probably be fixed by checking the input and the result types for RubyKObject... by why complicate a simple method?)
  def get_repo_by_id(id)
    @@settings['repositories'].find{ |repo| repo['id'] == id }
  end

  # return repo if the repo was added; otherwise, nil (eg. if all locations are the same as an existing one)
  # side-effects: creates the reviewed directory for the repo (but no other file system checks or saves)
  def add_repo(name, incoming_loc, my_loc = nil, outgoing_loc = nil, versioned = false)
    begin
      if (name.class.name == "RubyKObject") # for method results from Titanium
        name = name.toString()
      end
      if (incoming_loc != nil &&
          incoming_loc.class.name == "RubyKObject") # for method results from Titanium
        incoming_loc = incoming_loc.toString()
      end
      if (my_loc != nil &&
          my_loc.class.name == "RubyKObject") # for method results from Titanium
        my_loc = my_loc.toString()
      end
      if (outgoing_loc != nil &&
          outgoing_loc.class.name == "RubyKObject") # for method results from Titanium
        outgoing_loc = outgoing_loc.toString()
      end
      if (@@settings['repositories'].find{ |repo| repo['incoming_loc'] == incoming_loc && repo['my_loc'] == my_loc && repo['outgoing_loc'] == outgoing_loc } != nil)
        return nil
      end
      if (name.nil?)
        name = ""
      end
      # optimal: keep track of the max ID somewhere so that we don't reuse numbers
      maxRepo = @@settings['repositories'].max { |repo1,repo2| repo1['id'] <=> repo2['id'] }
      if (maxRepo == nil)
        max = 0
      else
        max = maxRepo['id'] + 1
      end
      new_repo = { 'id' => max, 'name' => name, 'incoming_loc' => incoming_loc, 'my_loc' => my_loc, 'outgoing_loc' => outgoing_loc, 'versioned' => versioned}
      FileUtils.mkpath reviewed_dir(new_repo)
    rescue
      return nil
    end
    @@settings['repositories'] << new_repo
    new_repo
  end

  # side-effects: renames the reviewed directory (but does no other file system checks or saves)
  def remove_repo(id)
    if (id.class.name == "RubyKObject") # for method results from Titanium
      id = id.toString()
    end
    id = id.to_i
    # archive the reviewed directory
    repo = get_repo_by_id(id)
    if (repo != nil)
      rev_dir = reviewed_dir(repo)
      if (File.exist? rev_dir)
        # move the old directory so that it's not lost and/or overridden
        archive_name = File.join(File.dirname(rev_dir), "archive_" + File.basename(rev_dir) + "_" + fixed_repo_name(repo['name']))
        if (File.exist? archive_name)
          count = 0
          while (File.exist? archive_name + "_" + count.to_s)
            count = count + 1
          end
          archive_name = archive_name + "_" + count.to_s
        end
        File.rename(rev_dir, archive_name)
      end
      # remove it from settings
      @@settings['repositories'].delete_if{ |repo| repo['id'] == id }
    end
  end


  def rename_repo(id, name)
    if (id.class.name == "RubyKObject") # for method results from Titanium
      id = id.toString()
    end
    id = id.to_i
    repo = get_repo_by_id(id)
    if (repo != nil)
      repo['name'] = name;
    end
  end

  def change_repo_incoming(id, incoming_loc)
    if (id.class.name == "RubyKObject") # for method results from Titanium
      id = id.toString()
    end
    id = id.to_i
    if (incoming_loc != nil &&
        incoming_loc.class.name == "RubyKObject") # for method results from Titanium
      incoming_loc = incoming_loc.toString()
    end
    get_repo_by_id(id)['incoming_loc'] = incoming_loc
  end

  def change_repo_my_loc(id, my_loc)
    if (id.class.name == "RubyKObject") # for method results from Titanium
      id = id.toString()
    end
    id = id.to_i
    if (my_loc != nil &&
        my_loc.class.name == "RubyKObject") # for method results from Titanium
      my_loc = my_loc.toString()
    end
    get_repo_by_id(id)['my_loc'] = my_loc
  end

  def change_repo_outgoing(id, outgoing_loc)
    if (id.class.name == "RubyKObject") # for method results from Titanium
      id = id.toString()
    end
    id = id.to_i
    if (outgoing_loc != nil &&
        outgoing_loc.class.name == "RubyKObject") # for method results from Titanium
      outgoing_loc = outgoing_loc.toString()
    end
    get_repo_by_id(id)['outgoing_loc'] = outgoing_loc
  end

end

#puts Settings.new("/Users/tlarson/Library/Application Support/Titanium/appdata/info.familyhistories.searchlocal").properties.to_s
