# restget.rb

require 'net/http'

def send_request(uri)
    begin
        resp = Net::HTTP.get_response(URI.parse(uri))
        puts resp.body
    rescue Exception => e
        puts "HTTP Request failed (#{e.message})"
    end
end

ARGV.each do |a|
	send_request a
end