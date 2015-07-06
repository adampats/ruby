#
# Create IAM Policy
# -Create new IAM Policy via AWS API / Ruby SDK
# -Provide policy document via JSON
#
# Parameters:
# -Policy Name
# -Policy Document (JSON format)
#
# Requires AWS IAM access keys be configured in aws.local.yml

require 'yaml'
require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'
require 'pry-byebug'
require 'json'

### Parameters
region = 'us-east-1' # Aws::IAM::Client.new requires a region parameter
usage = "Usage: create-iam-policy.rb [-n 'PolicyName'] [-p PolicyDocumentFile] [-v] [-h]"

options = {}
OptionParser.new do |opts|
  opts.banner = usage
  opts.on('-n', '--name PolicyName', 'IAM Policy Name') { |n| options[:policy_name] = n }
  opts.on('-p', '--policy PolicyDocumentFile', 'JSON Policy Document File') { |p| options[:policy_doc] = p }
  opts.on('-v', '--verbose', 'Turn on verbosity. Monitor all operations.') { options[:verbose] = true }
  opts.on('-h', '--help', 'Show this help message.') { puts opts ; exit}
end.parse!


### Script
if options.empty?
  puts "No command line parameters defined.  Quitting."
  puts usage
  exit
end

aws_yaml = YAML.load( File.read("aws.local.yml") )
ENV['AWS_SECRET_KEY_ID'] = aws_yaml['AWS_ACCESS_KEY_ID']
ENV['AWS_SECRET_ACCESS_KEY'] = aws_yaml['AWS_SECRET_ACCESS_KEY']

puts "Creating new IAM Policy, #{options[:policy_name]} ..." if options[:verbose]

iam = Aws::IAM::Client.new(region: region)
begin
    iam_policy = File.read( "#{options[:policy_doc]}" )
    resp_policy = iam.create_policy(policy_name: "#{options[:policy_name]}", policy_document: iam_policy)

rescue Exception => e
  puts "IAM Policy Creation failed - (#{e.message})"
end

puts "IAM Policy creation succeeded."
puts JSON.pretty_generate(resp_policy.to_hash) if options[:verbose]
puts "Done."
