#!/usr/bin/env ruby
#
# run in docker:
# cmd='ruby connectivity-logger.rb -h 8.8.8.8,192.168.0.1,192.168.100.1 -t 2 -i 3 -d 36000'
# docker run -d -v "$PWD":/usr/src/myapp -w /usr/src/myapp ruby:2.3.1-slim "$cmd"

require 'optparse'
require 'logger'

### Parameters
@verbose = true
@prog_name = $0.split('.')[0]
@log_name = "#{Time.now.strftime("%Y-%m-%d-%H%M%S")}-#{@prog_name}.log"

### Functions
def log(msg, sev = Logger::INFO)
  if @verbose
    puts "#{Time.now} - #{msg}" if @verbose
    STDOUT.flush
  end
  @log.add(sev, msg, @prog_name)
  return true
end

### Script

# Usage and Options
usage_message = " USAGE:  ruby #{@prog_name}.rb [-h host1,host2,host3] " +
  "[-t TIMEOUT] [-i INTERVAL] [-d DURATION]"
if ARGV.empty?
  puts "Please provide command line arguments.\n" + usage_message
  exit
end
options = {}
OptionParser.new do |opts|
  opts.banner = usage_message
  opts.on('-h', '--hosts host,ip,...', 'Hostnames or IPs to check') {
    |h| options[:hosts] = h }
  opts.on('-t', '--timeout SECONDS', 'Time in seconds before timeout') {
    |t| options[:timeout] = t.to_i }
  opts.on('-i', '--interval SECONDS', 'Time in seconds between checks') {
    |i| options[:interval] = i.to_i }
  opts.on('-d', '--duration SECONDS', 'How long to check connectivity') {
    |d| options[:duration] = d.to_i }
end.parse!

# Initialize log file
@log = Logger.new(@log_name)
log("Initialized")

begin
  # Gather hosts
  hosts = options[:hosts].split(/[, ]/).reject { |e| e.empty? }

  # Determine OS
  os = case Gem::Platform.local.os
    when 'darwin'
      count_flag = '-c'
      timeout_flag = '-t'
    when 'linux'
      count_flag = '-c'
      timeout_flag = '-w'
  end

  # Start pinging stuff
  # TODO: parallel pings for multiple hosts
  time_lapsed = 0
  while time_lapsed < options[:duration] do
    output = ""
    hosts.each do |h|
      cmd = "ping #{count_flag} 1 " +
        "#{timeout_flag} #{options[:timeout]} #{h} 2>/dev/null"
      result = `#{cmd}`.scan(/time=(.*)/).flatten.first
      output += "  #{h}: #{result.to_s}"
    end
    log(output)
    sleep options[:interval]
    time_lapsed += options[:interval]
  end

rescue Exception => e
  puts e.message
  puts e.backtrace
end

puts "Done"
