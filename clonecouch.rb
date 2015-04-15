# clonecouch.rb
#
# A script to pull all docs for a given couchdb database and write them locally or to another couchdb instance.
#

# Settings


# FUTURE - convert native HTTP calls to CouchREST
#require 'couchrest'
require 'optparse'
require 'net/http'
require 'json'
require 'pry-byebug'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: clonecouch.rb [-s https://HOSTNAME:PORT/DB] [-d https://HOSTNAME:PORT/DB] [-v]"
  opts.on('-s', '--sourcedb SOURCE_URL', 'Source CouchDB URL') { |s| options[:sourcedb] = s }
  opts.on('-d', '--destdb DEST_URL', 'Destination CouchDB URL') { |d| options[:destdb] = d }
  opts.on('-v', '--verbose', 'Turn on verbosity. Monitor all operations.') { |v| options[:verbose] = v }
  # FUTURE - add a token option for auth
end.parse!

def get_documents(url)
  begin
    uri = URI.parse("#{url}/_all_docs")
    params = { include_docs: true }
    uri.query = URI.encode_www_form(params)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.ssl_version = :SSLv3
    req = Net::HTTP::Get.new(uri)
    resp = http.request(req)
  rescue Exception => e
    puts "HTTP GET failed (#{e.message})"
  end
  json = JSON.parse(resp.body)
  return json
end

def put_document(url,doc)
	begin
    doc_id = doc['_id']
    doc_body = doc.tap { |hs| hs.delete('_id') } # remove the _id key from body
    uri = URI.parse("#{url}/#{doc_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.ssl_version = :SSLv3
    req = Net::HTTP::Put.new(uri)
    put_data = JSON.dump(doc_body)
    req.content_type = 'application/json'
    resp = http.request(req, put_data)
  rescue Exception => e
    puts "HTTP PUT failed (#{e.message})"
  end
end

### Script

source_db = options[:sourcedb]
dest_db = options[:destdb]
verbose_flag = options[:verbose]

puts "Beginning clone operation on:  #{source_db}"

source_docs = get_documents(source_db)
puts " #{source_docs['total_rows']} documents retrieved."

source_docs['rows'].each do |document|
  doc_id = document['id']
  print "\n#{doc_id} ... " if (verbose_flag)

  if (!doc_id.start_with?("_design"))
    doc_body = document['doc'].tap { |hs| hs.delete('_rev') } # remove the _rev key
    resp = put_document(dest_db,doc_body)
    print "#{resp.code}" if(verbose_flag)
  end

end

puts "\nClone to #{dest_db} complete."
