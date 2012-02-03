
#require 'gedcom'
#require File.join(File.expand_path(File.dirname(__FILE__)), "lib", "gedcom.rb")
#require File.join(File.expand_path(File.dirname(__FILE__)), "p2pdocs_utils.rb")

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

  def similarPeopleFound()
    @allSimilar.sort.map do |ind|
      {'indId'=>ind.id, 'name'=>ind.name, 'birth_date'=>ind.birth_date.to_s}
    end
  end

  def similarPeopleFoundJson()
    P2PDocsUtils.strings_arrays_hashes_json similarPeopleFound()
  end

end


class TreeExtractor < GEDCOM::Parser
  
  def initialize
    super
    @currentIndiInfo = nil
    @currentFamId = nil
    @familyToParentsHash = {}
    @childToInfoHash = {}
    
    
    # get individual info
    
    before %w(INDI) do |data|
      id = data[2..-2]
      @currentIndiInfo = {'INDI' => id}
      @childToInfoHash[id] = @currentIndiInfo
    end
    
    before %w(INDI NAME) do |data|
      @currentIndiInfo['NAME'] = data
    end
    
    #before %w(INDI _UID) do |data|
    #  @currentIndiInfo['_UID'] = data
    #end
    
    after %w(INDI) do
      @currentIndiInfo = nil
    end
    
    
    # now for the family info
    
    before %w(FAM) do |data|
      @currentFamId = data[2..-2]
    end
    
    before %w(FAM HUSB) do |data|
      id = data[2..-2]
      if (@familyToParentsHash[@currentFamId] == nil) then
        @familyToParentsHash[@currentFamId] = {}
      end
      @familyToParentsHash[@currentFamId]['HUSB'] = id
    end
    
    before %w(FAM WIFE) do |data|
      id = data[2..-2]
      if (@familyToParentsHash[@currentFamId] == nil) then
        @familyToParentsHash[@currentFamId] = {}
      end
      @familyToParentsHash[@currentFamId]['WIFE'] = id
    end
    
    before %w(FAM CHIL) do |data|
      id = data[2..-2]
      @childToInfoHash[id]['FAMC'] = @currentFamId
    end
    
    after %w(FAM) do
      @currentFamId = nil
    end

  end
  
  def retrieveTree(idToStartTree)
    info = @childToInfoHash[idToStartTree]
    current = {'info' => info}
    if (@childToInfoHash[idToStartTree] != nil) then
      #puts"family for #{idToStartTree}: #{@childToInfoHash[idToStartTree]}"
      famId = @childToInfoHash[idToStartTree]['FAMC']
      parents = @familyToParentsHash[famId]
      #puts"parents in family #{@childToInfoHash[idToStartTree]}: #{parents}"
      if (parents != nil) then
        if (parents['HUSB'] != nil) then
          current['pat'] = retrieveTree(parents['HUSB'])
        end
        if (parents['WIFE'] != nil) then
          current['mat'] = retrieveTree(parents['WIFE'])
        end
      end
    end
    return current
  end
  def retrieveTreeJson(idToStartTree)
    P2PDocsUtils.strings_arrays_hashes_json retrieveTree(idToStartTree)
  end

  
  def retrieveTreeAsUrlList(prefix, idToStartTree)
    allIds = retrieveTreeAsList2(retrieveTree(idToStartTree)).map{ |info|
      {"id" => prefix + "/" + info['INDI'], 'name' => info['NAME']}
    }
    allIds
  end
  def retrieveTreeAsList2(tree)
    if (tree == nil) then
      []
    else
      [tree['info']] + retrieveTreeAsList2(tree['pat']) + retrieveTreeAsList2(tree['mat'])
    end
  end
  def retrieveTreeAsUrlListJson(prefix, idToStartTree)
    P2PDocsUtils.strings_arrays_hashes_json retrieveTreeAsUrlList(prefix, idToStartTree)
  end
  
end


# Titanium gives an error if I try to create a new SimilarNameExtractor in a page... thus this method.
def newSimilarNameExtractor()
  return SimilarNameExtracter.new
end

def newTreeExtractor()
  return TreeExtractor.new
end
