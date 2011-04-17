require 'yaml'

# Usage:
# 1) Uncomment the last line(s) of this file, then:
# ruby settings.rb
# 2) ... or do this:
# ruby -e 'load "settings.rb"; SEE_END_OF_FILE'

class Settings

  VERSION = "0"

  @@settings = nil

  def initialize(dirname)

    #puts "class: " + dirname.class.to_s
    #dirname.public_methods.sort.each{|name| puts name }
    #dirname.methods.sort.each{|name| puts name }

    if (dirname.class.name == "RubyKObject") # for method results from Titanium
      @settings_dir = dirname.toString()
    else
      @settings_dir = dirname
    end

    if (@@settings == nil)

      if (File.exists? settings_file)
        @@settings = YAML.load_file(settings_file)
      end
      #YAML.dump(@settings)

    end
  end

  def data_dir
    @settings_dir
  end

  def settings_file
    File.join(@settings_dir, "settings.yaml")
  end

  def properties
    @@settings
  end

  def accepted_dir(repo)
    File.join(@settings_dir, "accepted_files", repo['name'].tr(" ", "_"))
  end

end

#puts Settings.new("/Users/tlarson/Library/Application Support/Titanium/appdata/info.familyhistories.searchlocal").properties.to_s
