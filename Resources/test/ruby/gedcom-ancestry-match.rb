
# doing them separately because I have to do that with Titanium; see identity.html.
require File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "ruby", "lib", "gedcom_date_parser.rb")
require File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "ruby", "lib", "gedcom_date.rb")
require File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "ruby", "lib", "gedcom.rb")
require File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "ruby", "gedcom-ancestry.rb")

file_name = ARGV.length > 0 ? ARGV[0] : File.join("Resources", "test", "royal.ged")
names_to_match = ARGV.length > 1 ? ARGV[1] : "victoria mary"

parser = SimilarNameExtracter.new
parser.setNamesToMatch names_to_match
parser.parse file_name

parser.similarPeopleFound().each{ |elem| puts elem.to_s + "\n" }




require File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "ruby", "p2pdocs_utils.rb")

puts parser.similarPeopleFoundJson()
