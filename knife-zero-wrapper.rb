# Run a chef-zero converge on an ubuntu server
#
# Bootstrapper should be run first!
#
# Does the following:
# => Aggregates dependency cookbooks locally
# => Triggers a chef-client run in local mode (chef-zero)
#
# Requirements:
# => Some regular gems - See Gemfile
# => Some chef gems - chef gem install knife-zero
#
# Usage:
#  ruby knife-zero-wrapper.rb -c config.yml

require 'rest_client'
require 'json'
require 'pry-byebug'
require 'yaml'
require 'base64'
require 'net/ssh'
require 'optparse'

### Parameters

### Functions
def validate_ssh_connection(p_hash)
  resp = Net::SSH.start( p_hash[:node],
    p_hash[:username], keys: [p_hash[:ssh_key]]) do |ssh|
      result = ssh.exec!("hostname -A")
      ( result.include?( p_hash[:node] )) ? true : false
  end
end

def run_cmd(cmd)
  begin
    out = IO.popen(cmd).read
  rescue => e
    puts "Failed to run command: #{cmd}"
    puts "Error message: #{e.message}"
  end
end

### Script

# Usage and Options
usage_message=" USAGE:  ruby knife-zero-wrapper.rb -s [NODE_NAME] -r [RUN_LIST] -u [USER] -i [SSH_KEY] -k [SECRET_KEY]"
if ARGV.empty?
  puts "Please provide arguments."
  puts usage_message
  exit
end
options = {}
OptionParser.new do |opts|
  opts.banner = usage_message
  opts.on('-s', '--node_name HOSTNAME', 'Hostname of node to converge on') {
    |s| options[:node] = s }
  opts.on('-r', '--run_list [RECIPE]', 'Runlist to converge in format: cookbook::recipe') {
    |r| options[:run_list] = r }
  opts.on('-u', '--username USER', 'Username to SSH to node as. Defaults to ubuntu') {
    |u| options[:username] = u }
  opts.on('-i', '--ssh_key FILE', 'SSH private key to connect with. Defaults to ~/.ssh/id_rsa') {
    |i| options[:ssh_key] = i }
  opts.on('-k', '--secret_key FILE', 'Data bag secret key. Defaults to ./encrypted_data_bag_secret') {
    |k| options[:secret] = k }
end.parse!

# Default values
options[:username] ||= "ubuntu"
options[:ssh_key] ||= "~/.ssh/id_rsa"
options[:secret] ||= "./encrypted_data_bag_secret"
options[:run_list] = [ options[:run_list] ]

# Validate connectivity + dependencies
print "Validating SSH to node..."
server_avail = validate_ssh_connection( options )
if !server_avail
  puts "Fail"
  puts "Error - unable to SSH to #{options[:node]} for some reason.  Exiting."
  exit
end
puts "Success"

print "Checking for local Knife-Zero..."
command = %Q{knife zero --help 2>/dev/null}
if ! run_cmd(command).include? "ZERO COMMANDS"
  puts "Fail"
  puts "knife zero doesn't appear to be available - please install it, i.e. "
  puts "chef gem install knife-zero"
end
puts "Success"

# Chef run

# Vendor cookbook dependencies with Berkshelf
options[:run_list].each do |cookbook|
  cb = cookbook.split("::")[0]
  command = %Q{berks vendor --berksfile=cookbooks/#{cb}/Berksfile \
    ./#{cb}-cookbooks}
  command += %Q{ && mkdir ./berks-cookbooks}
  command += %Q{ && cp -R ./#{cb}-cookbooks/* ./berks-cookbooks/}
  command += %Q{ && rm -Rf ./#{cb}-cookbooks}
  run_cmd(command)
end

# Knife Bootstrap
command = %Q{knife zero bootstrap -z #{options[:node]} \
  --ssh-user #{options[:username]} \
  --identity-file #{options[:ssh_key]} \
  --sudo \
  --run-list recipe#{options[:run_list]} \
  --secret-file #{options[:secret]} \
  --converge }
puts "Running knife command: \n #{command} \n ..."
puts run_cmd(command)

# Local cleanup
command = %Q{rm -Rf ./berks-cookbooks}
run_cmd(command)

puts "\nDone."
