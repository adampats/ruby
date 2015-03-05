# a sample of using command line arguments in a ruby script

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: cli_args.rb [-s http://HOSTNAME:PORT/DB] [-d http://HOSTNAME:PORT/DB] [-v]"
  opts.on('-s', '--sourcedb SOURCE_URL', 'Source CouchDB URL') { |s| options[:sourcedb] = s }
  opts.on('-d', '--destdb DEST_URL', 'Destination CouchDB URL') { |d| options[:destdb] = d }
  opts.on('-v', '--verbose', 'Turn on verbosity. Monitor all operations.') { |v| options[:verbose] = v }
end.parse!
