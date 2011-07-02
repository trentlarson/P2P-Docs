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
  # format: { repositories => [ { name => "", source_dir => "" } ... ] }
  # see test settings.rb for example structures
  BLANK_SETTINGS = {'repositories' => []}
  @@settings = BLANK_SETTINGS


=begin
May be empty.
May reference a settings.yaml file.
=end
  def initialize(dirname)

    #puts "class: " + dirname.class.to_s
    #dirname.public_methods.sort.each{|name| puts name }
    #dirname.methods.sort.each{|name| puts name }

    if (dirname.class.name == "RubyKObject") # for method results from Titanium
      @@settings_dir = dirname.toString()
    else
      @@settings_dir = dirname
    end

    if (@@settings == BLANK_SETTINGS)
      if (File.exist? settings_file())
        @@settings = YAML.load_file(settings_file())
      end
      #YAML.dump(@settings)
    end

    FileUtils.mkdir_p(reviewed_base_dir())
  end

  def replace(new_settings_data)
    @@settings = new_settings_data
    File.open(settings_file(), 'w') do |out|
      YAML.dump(new_settings_data, out)
    end
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

  def add_repo(name, source_dir)
    if (name.class.name == "RubyKObject") # for method results from Titanium
      name = name.toString()
    end
    if (source_dir.class.name == "RubyKObject") # for method results from Titanium
      source_dir = source_dir.toString()
    end
    @@settings['repositories'] << { 'name' => name, 'source_dir' => source_dir }
  end

  def remove_repo(name)
    if (name.class.name == "RubyKObject") # for method results from Titanium
      name = name.toString()
    end
    @@settings['repositories'].delete_if{ |repo| repo['name'] == name }
  end

  def change_repo_path(name, new_path)
    if (name.class.name == "RubyKObject") # for method results from Titanium
      name = name.toString()
    end
    @@settings['repositories'].find{ |repo| repo['name'] == name }['source_dir'] = new_path
  end

  def save()
    File.open(settings_file(), 'w') do |out|
      YAML.dump(@@settings, out)
    end
  end

end

#puts Settings.new("/Users/tlarson/Library/Application Support/Titanium/appdata/info.familyhistories.searchlocal").properties.to_s
