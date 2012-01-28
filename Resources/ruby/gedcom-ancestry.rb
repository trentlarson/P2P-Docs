
#require 'gedcom'
#require File.join(File.expand_path(File.dirname(__FILE__)), "lib", "gedcom.rb")

class Individual
  attr_accessor :id
  attr_accessor :name
  attr_accessor :birth_date

  def initialize( id = nil, name = nil, birth_date = nil)
    @id, @name, @birth_date = id, name, birth_date
  end

  def <=>( b )
    name <=> b.name
  end
end


class SimilarNameExtracter < GEDCOM::Parser
  @namesToMatch = nil

  def initialize
    super
    @currentPerson = nil
    @allSimilar = []
    
    before %(INDI) do |data|
      @currentPerson = Individual.new data[2..-2]
    end

    before %w(INDI NAME) do |data|
      upcased = data.upcase
      if @namesToMatch.all? { |name| upcased.match(name) }
        @currentPerson.name = data if @currentPerson.name == nil
        @allSimilar << @currentPerson
      end
    end

    before %w(INDI BIRT DATE) do |data|
      if @currentPerson.birth_date == nil
        d = GEDCOM::Date.safe_new( data )
        if d.is_date?
          @currentPerson.birth_date = d
        end
      end
    end

    after %w(INDI) do
      @currentPerson = nil
    end
  end

  def setNamesToMatch(names)
    @namesToMatch = names.upcase.split(" ")
  end

  def showSimilarPeople( )
    puts "=- none -=" if @allSimilar.size == 0
    @allSimilar.sort.each do |ind|
      puts "#{ind.id}\t #{ind.name} #{ind.birth_date}"
    end
  end

end

# Titanium gives an error if I try to create a new SimilarNameExtractor in a page... thus this method.
def newSimilarNameExtractor()
  return SimilarNameExtracter.new
end

# Uncomment these to run tests via command-line.

#parser = SimilarNameExtracter.new

# either grab command-line arguments
#if ARGV.length < 2
#  puts "Please specify the name of a GEDCOM file and a person's name."
#  exit(0)
#end
#parser.setNamesToMatch ARGV[1]
#parser.parse ARGV[0]

# ... or get defaults
#parser.setNamesToMatch "victoria"
#parser.parse "Resources/test/royal.ged"

#parser.showSimilarPeople()
