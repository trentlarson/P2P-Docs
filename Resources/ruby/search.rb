
require 'CGI'

# Usage:
# ruby search.rb /Users/tlarson/backed/doc/family-histories/JeanGould.html dog
# ruby -e 'load "search.rb"; Search.new.main("/Users/tlarson/backed/doc/family-histories/JeanGould.html","dog")' search.rb

class Search

  def main(file, term)

    lines = []
    File.open(file) do |io|
      io.each do |line|
        line.chomp!
        lines << { "file" => file, "line" => line } if line.include? term
      end
    end

    lines

  end

end

#Search.new.main(ARGV[0], ARGV[1])
