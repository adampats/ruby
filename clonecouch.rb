# clonecouch.rb
#
# A script to pull all docs for a given couchdb database and write them locally or to another couchdb instance.
#

# FUTURE - convert native HTTP calls to CouchREST
#require 'couchrest'
require 'optparse'
require 'net/http'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: clonecouch.rb [-s http://HOSTNAME:PORT/DB] [-d http://HOSTNAME:PORT/DB] [-v]"
  opts.on('-s', '--sourcedb SOURCE_URL', 'Source CouchDB URL') { |s| options[:sourcedb] = s }
  opts.on('-d', '--destdb DEST_URL', 'Destination CouchDB URL') { |d| options[:destdb] = d }
  opts.on('-v', '--verbose', 'Turn on verbosity. Monitor all operations.') { |v| options[:verbose] = v }
  # FUTURE - add a token option for auth
end.parse!

def get_document(uri, db, doc)
    begin
        resp = Net::HTTP.get_response(URI.parse("#{uri}/#{db}/#{doc}"))
    rescue Exception => e
        puts "HTTP GET failed (#{e.message})"
    end
    resp.body
end

def put_document(uri, port, db, doc, docdata)
	begin
        http = Net::HTTP.new(uri, port)
        resp = http.send_request('PUT', "/#{db}/#{doc}", docdata)
    rescue Exception => e
        puts "HTTP PUT failed (#{e.message})"
    end
end

puts "Beginning clone operation on:  #{options[:sourcedb]}"

source_docs = http://lx01251.starbucks.net:5984/tailcert1/_all_docs

source_docs.each do |document|
	get_document(options[asdfasdfasdfasdfasdf])

# validate URLs / catch connection errors
#@db = CouchRest.database(options[:sourcedb])


