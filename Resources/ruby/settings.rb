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

      filename = File.join(@settings_dir, "settings.yaml")

      if (File.exists? filename) 
        @@settings = YAML.load_file(filename)
      else
        @@settings = {}
      end
      #YAML.dump(@settings)

    end
  end

  def dir()
    @settings_dir
  end

  def getProperties()
    @@settings
  end

  def testProperties()
    {'repositories'=>
       [{'name'=>'test 0', 'path'=>'/Users/tlarson/hacked'},
        {'name'=>'test 1', 'path'=>'/Users/tlarson/hacked-again'}]
    }
  end

end

#puts Settings.new("/Users/tlarson/Library/Application Support/Titanium/appdata/info.familyhistories.searchlocal").getProperties().to_s
