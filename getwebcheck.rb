# checkweb.rb
#
# Check an endpoint for a specific HTTP response code
#  -pass CLI args or set environment variables:
#     URL          Host/endpoint to check
#     RESP_CODE    HTTP response code to wait for
#     INTERVAL     Frequency of checks
#     TIMEOUT      How long before timing out

require 'optparse'
require 'rest_client'

# Usage and Options
usage_message = "usage:  checkweb.rb [-u http://URL] \n" +
  "\toptional: [-r RESP_CODE] [-i INTERVAL] [-t TIMEOUT] [-v] \n" +
  "\talternatively: set ENV vars: URL, RESP_CODE, INTERVAL, TIMEOUT"

opts = {}
OptionParser.new do |o|
  o.banner = usage_message
  o.on('-u', '--url WEB_URL', 'Hostname / URL to check', String) { |u|
    opts[:url] = u }
  o.on('-r', '--response CODE', 'HTTP Response Code', Integer) { |r|
    opts[:resp] = r }
  o.on('-i', '--interval', 'Seconds between checks', Integer) { |i|
    opts[:intv] = i }
  o.on('-t', '--timeout', 'Seconds until timeout', Integer) { |t|
    opts[:timeout] = t }
  o.on('-v', '--verbose', 'Turn on verbosity') { |v|
    opts[:verbose] = v }
end.parse!

### Script

begin
  # Defaults & precedence
  url ||= opts[:url] ||= ENV['URL'] ||= "http://localhost"
  code ||= opts[:resp] ||= ENV['RESP_CODE'] ||= '200'
  intv ||= opts[:intv] ||= ENV['INTERVAL'] ||= '2'
  timeout ||= opts[:timeout] ||= ENV['TIMEOUT'] ||= '120'

  puts "Starting GETs to #{url} until a #{code} response is received."
  count = 0
  match = false
  while count < timeout.to_i && match == false
    count += 1
    sleep intv.to_i
    begin
      print count * intv.to_i if opts[:verbose]
      print "."
      resp = RestClient.get(url)
      if resp.code == code.to_i
        print "{#{resp.code}}"
        match = true
      end
    rescue Exception => w
      puts w.message if opts[:verbose]
    end
  end
  puts "\nMatch at #{Time.now}!"

rescue Exception => e
  puts "Exception."
  puts e.message
  puts e.backtrace.inspect
end
