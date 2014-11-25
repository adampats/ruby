# clonecouch.rb
#
# A script to pull all docs for a given couchdb database and write them locally or to another couchdb instance.
#

require 'couchrest'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: clonecouch.rb [-s http://HOSTNAME:PORT/DB] [-d http://HOSTNAME:PORT/DB] [-v]"
  opts.on('-s', '--sourcedb SOURCE_URL', 'Source CouchDB URL') { |s| options[:sourcedb] = s }
  opts.on('-d', '--destdb DEST_URL', 'Destination CouchDB URL') { |d| options[:destdb] = d }
  opts.on('-v', '--verbose', 'Turn on verbosity. Monitor all operations.') { |v| options[:verbose] = v }
  # add a token option for auth
end.parse!

puts "Beginning clone operation on:  #{options[:sourcedb]}"

# validate URLs / catch connection errors
#@db = CouchRest.database(options[:sourcedb])

# couchrest stuff
