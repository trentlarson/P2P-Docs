
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
    filenames = search_dirs_from(settings).map{ |dir| all_files_below(dir) }.flatten.sort.uniq
    
    lines = []
    filenames.each do |filename|
      pos = nil
      File.open(filename) do |io|
        io.each do |line|
          length = line.length # do this before chomping the line-ending characters
          line = line.chomp
          # This is a hack to avoid binary files, particularly because we'll crash later on the term matching.  Ideally, we should notify the user, or use some settings to avoid these.
          if (line.bytes.to_a.index{|b| b < 9 || (9 < b && b < 32) || b == 127 }) # this detects non-printable characters, besides tab... but we've got to allow international characters
          #if (line.bytes.to_a.index(0)) # this detects a 0 character, which may be enough
            break
          end
          lines << { "file" => filename, "context" => line, "position" => pos } if line.include? term
          # now save any anchor in there for future hits
          # (not doing this before the match in case the anchor is after the term)
          anames = line.scan(/<a name="(.+?)"/)
          if (anames.length > 0)
            pos = anames[0].last
          else
            anames = line.scan(/<a name='(.+?)'/)
            if (anames.length > 0)
              pos = anames[0].last
            end
          end
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
  
end

#puts Search.new.main(ARGV[0], ARGV[1])
