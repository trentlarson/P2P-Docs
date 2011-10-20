
# Usage:
# 1) Uncomment the last line of this file, then:
# ruby search.rb /Users/tlarson/backed/doc/family-histories/JeanGould.html dog
# 2) ... or do this:
# ruby -e 'load "search.rb"; Search.new.main("/Users/tlarson/backed/doc/family-histories/JeanGould.html","dog")'

class Search

  # filename can be directory or single file
  # return an array of hashes: file => filename, line => line with matching text, pos => file position of beginning of line
  def main(settings, term)

    if (term.class.name == "RubyKObject") # for method results from Titanium
      term = term.toString()
    end
    
    #filenames = all_files_below(filename)
    filenames = search_dirs_from(settings).map{ |dir| all_files_below(dir) }.flatten
    
    lines = []
    filenames.each do |filename|
      pos = 0
      File.open(filename) do |io|
        io.each do |line|
          length = line.length # do this before chomping the line-ending characters
          line.chomp!
          lines << { "file" => filename, "context" => line, "pos" => pos } if line.include? term
          pos += length
        end
      end
    end
    lines
  end
  
  # return all the repository directories in which to search for content, meaning the home directory or (if that's not set) the incoming directory
  def search_dirs_from(settings)
    settings.properties['repositories'].map{ |repo| 
      if (repo['my_loc'] != nil)
        repo['my_loc']
      elsif (repo['incoming_loc'] != nil)
        repo['incoming_loc']
      else
        nil
      end
    }.reject{ |loc| loc.nil? }
  end
  
  # return a list, may be empty, never nil
  def all_files_below(dirname)
    result = all_files_below_rec(dirname)
    result == nil ? [] : result.flatten
  end
  # return a list of file names, may be empty, nil if dirname is not an existing file or directory
  def all_files_below_rec(dirname)
    if (File.file?(dirname))
      [dirname]
    elsif (File.directory?(dirname))
      entries = Dir.new(dirname).entries.reject{ |entry| entry == "." || entry == ".." }
      entries.map{ |entry| all_files_below(File.join(dirname, entry)) }
    end
  end
  
  

  BUFFER_LENGTH = 2048
  
  # return the XML anchor name attribute value before the given position, or nil if none found in BUFFER_LENGTH beforehand
  def previous_anchor_name(filename, filepos)
    if (filename.class.name == "RubyKObject") # for method results from Titanium
      filename = filename.toString()
    end
    if (filepos.class.name == "RubyKObject") # for method results from Titanium
      filepos = filepos.toString().to_i
    elsif (filepos.class.name == "String")
      filepos = filepos.to_i
    end
    
    buffer = ""
    File.open(filename) do |io|
      io.seek(filepos - BUFFER_LENGTH)
      buffer = io.read(BUFFER_LENGTH) # if it's longer than this, we'll just give up (and they'll have to search)
    end
    names = buffer.scan(/<a name="(.+?)"/)
    if (names.length > 0)
      return names.last.last
    else
      names = buffer.scan(/<a name='(.+?)'/)
      if (names.length > 0)
        return names.last.last
      else
        return nil
      end
    end
  end


end

#puts Search.new.main(ARGV[0], ARGV[1])
