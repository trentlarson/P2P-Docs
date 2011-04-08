
require 'CGI'

# Usage:
# ruby search.rb /Users/tlarson/backed/doc/family-histories/JeanGould.html dog
# ruby -e 'load "search.rb"; Search.new.main("/Users/tlarson/backed/doc/family-histories/JeanGould.html","dog")' search.rb

class Search

  # return an array of hashes: file => filename, line => line with matching text, pos => file position of beginning of line
  def main(filename, term)

    lines = []
    pos = 0
    File.open(filename) do |io|
      io.each do |line|
        length = line.length # do this before chomping the line-ending characters
        line.chomp!
        lines << { "file" => filename, "line" => line, "pos" => pos } if line.include? term
        pos += length
      end
    end

    lines

  end

  BUFFER_LENGTH = 2048
  # return the XML anchor name attribute value before the given position, or nil if none found in BUFFER_LENGTH beforehand
  def previous_anchor_name(filename, filepos)
    buffer = ""
    File.open(filename) do |io|
      io.seek(filepos - BUFFER_LENGTH)
      buffer = io.read(BUFFER_LENGTH) # if it's longer than this, we'll just give up (and they'll have to search)
    end
    names = buffer.scan(/<a name="(.+?)"/)
    if (names.length > 0)
      return names.last.last
    else
      return nil
    end
  end


end

#Search.new.main(ARGV[0], ARGV[1])
