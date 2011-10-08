require 'yaml'
require 'fileutils'

# command-line usage:
# 1) Uncomment the last line(s) of this file, then:
# ruby settings.rb
# 2) ... or do this:
# ruby -e 'load "settings.rb"; SEE_END_OF_FILE'

class Settings

  VERSION = "0"
  
  @@settings_dir = ""
  # format: { 'repositories' => [ { 'id' => NUM, 'name' => 'XYZ', 'incoming_loc' => 'XYZ', 'my_loc' => 'XYZ', 'outgoing_loc' => 'XYZ', 'not_versioned' => false|true } ... ] }
  #   where incoming_loc / my_loc / outgoing_loc values may be nil
  # see test settings.rb for example structures
  BLANK_SETTINGS = {'repositories' => []}
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
  
  def reviewed_dir(repo = nil)
    if (repo == nil)
      reviewed_base_dir
    elsif (repo.class.name == "String")
      # allow the raw name
      File.join(reviewed_base_dir, fixed_repo_name(repo))
    else
      File.join(reviewed_base_dir, fixed_repo_name(repo['name']))
    end
  end

  def get_repo_by_id(id)
    @@settings['repositories'].find{ |repo| repo['id'] == id }
  end

  def get_repo_by_name(name)
    @@settings['repositories'].find{ |repo| repo['name'] == name }
  end

  # return repo if the repo was added; otherwise, nil (eg. name blank or duplicate)
  # side-effects: creates the reviewed directory for the repo (but no other file system checks or saves)
  def add_repo(name, incoming_loc, my_loc = nil, outgoing_loc = nil, not_versioned = false)
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
      fixed_name = fixed_repo_name(name)
      if ((name.nil?) ||
          (name == "") ||
          (@@settings['repositories'].find{ |repo| repo['name'] == name || fixed_repo_name(repo['name']) == name || repo['name'] == fixed_name } != nil))
        return nil
      end
      maxRepo = @@settings['repositories'].max { |repo1,repo2| repo1['id'] <=> repo2['id'] }
      if (maxRepo == nil)
        max = 0
      else
        max = maxRepo['id'] + 1
      end
      new_repo = { 'id' => max, 'name' => name, 'incoming_loc' => incoming_loc, 'my_loc' => my_loc, 'outgoing_loc' => outgoing_loc, 'not_versioned' => not_versioned}
      FileUtils.mkpath reviewed_dir(new_repo)
    rescue
      return nil
    end
    @@settings['repositories'] << new_repo
    new_repo
  end

  # side-effects: renames the reviewed directory (but does no other file system checks or saves)
  def remove_repo(name)
    if (name.class.name == "RubyKObject") # for method results from Titanium
      name = name.toString()
    end
    # archive the reviewed directory
    repo = get_repo_by_name(name)
    if (repo != nil)
      if (File.exist? reviewed_dir(repo))
        # move the old directory so that it's not lost and/or overridden
        archive_base_name = reviewed_dir(repo) + "_archive"
        count = 0
        while (File.exist? archive_base_name + "_" + count.to_s)
          count = count + 1
        end
        File.rename(reviewed_dir(repo), archive_base_name + "_" + count.to_s)
      end
      # remove it from settings
      @@settings['repositories'].delete_if{ |repo| repo['name'] == name }
    end
  end

  def change_repo_incoming(name, incoming_loc)
    if (name.class.name == "RubyKObject") # for method results from Titanium
      name = name.toString()
    end
    if (incoming_loc != nil &&
        incoming_loc.class.name == "RubyKObject") # for method results from Titanium
      incoming_loc = incoming_loc.toString()
    end
    get_repo_by_name(name)['incoming_loc'] = incoming_loc
  end

  def change_repo_my_loc(name, my_loc)
    if (name.class.name == "RubyKObject") # for method results from Titanium
      name = name.toString()
    end
    if (my_loc != nil &&
        my_loc.class.name == "RubyKObject") # for method results from Titanium
      my_loc = my_loc.toString()
    end
    get_repo_by_name(name)['my_loc'] = my_loc
  end

  def change_repo_outgoing(name, outgoing_loc)
    if (name.class.name == "RubyKObject") # for method results from Titanium
      name = name.toString()
    end
    if (outgoing_loc != nil &&
        outgoing_loc.class.name == "RubyKObject") # for method results from Titanium
      outgoing_loc = outgoing_loc.toString()
    end
    get_repo_by_name(name)['outgoing_loc'] = outgoing_loc
  end

end

#puts Settings.new("/Users/tlarson/Library/Application Support/Titanium/appdata/info.familyhistories.searchlocal").properties.to_s
