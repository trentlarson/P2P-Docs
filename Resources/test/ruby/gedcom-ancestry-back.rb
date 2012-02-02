
# doing them separately because I have to do that with Titanium; see identity.html.
require File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "ruby", "lib", "gedcom_date_parser.rb")
require File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "ruby", "lib", "gedcom_date.rb")
require File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "ruby", "lib", "gedcom.rb")
require File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "ruby", "gedcom-ancestry.rb")

file_name = ARGV.length > 0 ? ARGV[0] : File.join("Resources", "test", "royal.ged")
id_to_start_tree = ARGV.length > 1 ? ARGV[1] : "2"

parser = TreeExtractor.new
#parser = TreeExtracter.new
parser.parse file_name 

#parser.retrieveTree(id_to_start_tree).each{ |elem| puts elem.to_s + "\n" }
puts parser.retrieveTree(id_to_start_tree).to_s + "\n"
