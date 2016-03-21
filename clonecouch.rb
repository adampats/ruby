# clonecouch.rb
#
# A script to pull all docs for a given couchdb database and write them
#   locally or to another couchdb instance.
#

require 'optparse'
require 'rest_client'
require 'json'
require 'pry-byebug'
require 'uri'
require 'base64'

# Usage and Options
usage_message = "Usage: clonecouch.rb [options]" +
  "\t[-s https://HOSTNAME:PORT/DB] [-d https://HOSTNAME:PORT/DB]" +
  "\t[-u USER] [-p PASSWORD] [-e] [-v]"
if ARGV.empty?
  puts "Please provide arguments."
  puts usage_message
  exit
end
opts = {}
OptionParser.new do |opt|
  opt.banner = usage_message
  opt.on('-s', '--sourcedb SOURCE_URL', 'Source CouchDB URL', String) { |s|
    opts[:sourcedb] = s }
  opt.on('-d', '--destdb DEST_URL', 'Destination CouchDB URL', String) { |d|
    opts[:destdb] = d }
  opt.on('-u', '--user USER', 'CouchDB admin username', String) { |u|
    opts[:user] = u }
  opt.on('-p', '--password PASSWORD', 'CouchDB admin password', String) { |p|
    opts[:pass] = p }
  opt.on('-e', '--designdocs', 'Include _design docs') { |e|
    opts[:design] = e }
  opt.on('-v', '--verbose', 'Turn on verbosity') { |v|
    opts[:verbose] = v }
end.parse!

### Functions
def couch_init(couchdb_url)
  couch = RestClient::Resource.new(
    couchdb_url,
    headers: {
      content_type: :json,
      accept: :json
    },
    verify_ssl: false,
    ssl_version: 'SSLv3'
    )
    return couch
end

def get_all_docs(couch_rest)
  response = couch_rest["/_all_docs?include_docs=true"].get
  return JSON.parse(response)
end

def base_auth(creds = {})
  auth = 'Basic ' + Base64.encode64( creds[:user] + ':' + creds[:pass] ).chomp
  return auth
end

def put_design_doc(couch_rest, doc = {}, auth)
  response = couch_rest[ doc['_id'] ].put( doc.to_json, authorization: auth )
  return response
end

def post_bulk_docs(couch_rest, docs)
  response = couch_rest["_bulk_docs"].post( docs.to_json )
  return response
end

### Script

begin
  puts "Beginning clone operation on:  #{opts[:sourcedb]} ..."
  @s_couch = couch_init( opts[:sourcedb] )
  @d_couch = couch_init( opts[:destdb] )
  destdb = URI( opts[:destdb] ).path.split('/').last

  # validate source db
  source_check = @s_couch.get rescue nil
  if source_check.nil?
    raise "Source DB doesn't exist."
  end

  # create the db if it doesn't exist
  dest_check = @d_couch.get rescue nil
  if dest_check.nil?
    creds = { user: opts[:user], pass: opts[:pass] }
    @auth = base_auth( creds )
    resp = @d_couch.put( destdb, authorization: @auth )
    puts "Dest DB creation: " + resp.code.to_s
  else
    raise "Destination DB already exists, please delete first."
  end

  s_hash = get_all_docs( @s_couch )
  puts " #{s_hash['total_rows']} documents retrieved."

  puts "Doing bulk POST into #{opts[:destdb]} ..."
  bulk_docs = { "docs" => [] }
  s_hash['rows'].each do |doc|
    print "#{doc['id']}," if ( opts[:verbose] )
    # TODO: add _rev handling for overwriting DBs / creating new ones

    if ( !doc['id'].start_with?("_design") )
      bulk_docs['docs'] << doc['doc'].tap { |h| h.delete('_rev') }
    else
      resp = put_design_doc( @d_couch,
        doc['doc'].tap { |h| h.delete('_rev') },
        @auth )
      puts "_design doc created: #{doc['doc']['_id']}" if resp.code == 201
    end
  end

  resp = post_bulk_docs( @d_couch, bulk_docs )
  puts "Response code: #{resp.code}"
  puts "Clone to #{destdb} complete."

rescue Exception => e
  puts "Exception: " + e.message
  puts e.backtrace.inspect
end

puts "Done."
