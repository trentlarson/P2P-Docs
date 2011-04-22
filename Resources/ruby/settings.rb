require 'yaml'

# Usage:
# 1) Uncomment the last line(s) of this file, then:
# ruby settings.rb
# 2) ... or do this:
# ruby -e 'load "settings.rb"; SEE_END_OF_FILE'

class Settings

  VERSION = "0"

  @@settings_dir = ""
  @@settings = nil


=begin
May be empty.
May contain a settings.yaml file; see SettingsTest.two_repos for an example structure.
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

    if (@@settings == nil)
      if (File.exists? settings_file)
        @@settings = YAML.load_file(settings_file)
      end
      #YAML.dump(@settings)
    end
  end

  def replace(new_settings_data)
    @@settings = new_settings_data
    File.open(settings_file(), 'w') do |out|
      YAML.dump(new_settings_data, out)
    end
  end

  def settings_file
    File.join(@@settings_dir, "settings.yaml")
  end

  def data_dir
    @@settings_dir
  end

  def properties
    @@settings
  end

  def accepted_base_dir
    File.join(@@settings_dir, "accepted_files")
  end

  def accepted_dir(repo = nil)
    if (repo == nil)
      accepted_base_dir
    elsif (repo.class.name == "String")
      # allow the raw name
      File.join(accepted_base_dir, repo.tr(" ", "_"))
    else
      File.join(accepted_base_dir, repo['name'].tr(" ", "_"))
    end
  end

end

#puts Settings.new("/Users/tlarson/Library/Application Support/Titanium/appdata/info.familyhistories.searchlocal").properties.to_s
