
require 'CGI'

# ruby search.rb /Users/tlarson/backed/doc/family-histories/JeanGould.html dog
# ruby -e 'load "search.rb"; Search.new.main("/Users/tlarson/backed/doc/family-histories/JeanGould.html","dog")' search.rb

class Search

  @locator_path = File.expand_path("locate.html")

  RELATIVE_PATHS = Hash.new

  def rel_to_locate(file)
    return RELATIVE_PATHS[file] if RELATIVE_PATHS.has_key? file
    prefix = file.dup
    prefix.chop! while @locator_path.index(prefix) != 0

    locator_after_prefix = @locator_path.sub(prefix, "")
    up_dirs = Array.new(locator_after_prefix.count(File::SEPARATOR)).fill("..").join(File::SEPARATOR)
    RELATIVE_PATHS[file] = file.sub(prefix, up_dirs + File::SEPARATOR)
  end


  def main(file, term)

    lines = []
    File.open(file) do |io|
      io.each do |line|
        line.chomp!
        lines << { "file" => file, "line" => line } if line.include? term
      end
    end

#    links = lines.collect { |line| "<a href='locate.html?file_url=#{CGI::escape(rel_to_locate(line['file']))}'>#{line['line']}</a>" }
#    links = lines.collect { |line| "<a href='locate.html?file_url=#{CGI::escape(line['file'])}'>#{line['line']}</a>" }

    lines

  end

end

#Search.new.main(ARGV[0], ARGV[1])
