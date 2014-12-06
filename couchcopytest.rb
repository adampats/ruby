# restget.rb

require 'net/http'

source_uri = 'https://lx01251.starbucks.net:6984'
source_db = 'tailcert1'
source_doc = 'amsbc001.starbucks.net'

# do not include http:// or port in the destination or put method will fail
destination_uri = 'localhost'
destination_port = 5984
destination_db = 'taildevtest'
destination_doc = 'amsbc001.starbucks.net'

def getrequest(uri, db, doc)
    begin
        resp = Net::HTTP.get_response(URI.parse("#{uri}/#{db}/#{doc}"))
    rescue Exception => e
        puts "HTTP GET failed (#{e.message})"
    end
    resp.body
end

def putrequest(uri, port, db, doc, docdata)
    begin
        http = Net::HTTP.new(uri, port)
        resp = http.send_request('PUT', "/#{db}/#{doc}", docdata)
    rescue Exception => e
        puts "HTTP PUT failed (#{e.message})"
    end
end

source_data = getrequest(source_uri, source_db, source_doc)

puts "\n" + source_data + "\n"

putrequest(destination_uri, destination_port, destination_db, destination_doc, source_data)