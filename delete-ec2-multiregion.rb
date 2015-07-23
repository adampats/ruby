# Delete/cleanup instances and SGs from the create-ec2-multiregion.rb script
# Parameters:
# -file name of resources from create-ec2-multiregion.rb
#
# Requires AWS IAM access keys be configured in aws.local.yml

require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'
require 'uuid'
require 'pry-byebug'
require 'json'

### Parameters
authfile = 'aws.local.yml'
@regions = [
  { region: 'us-east-1', count: @num_instances },
  { region: 'us-west-2', count: @num_instances },
  { region: 'us-west-1', count: @num_instances },
  { region: 'eu-west-1', count: @num_instances },
  { region: 'eu-central-1', count: @num_instances },
  { region: 'ap-southeast-1', count: @num_instances },
  { region: 'ap-southeast-2', count: @num_instances },
  { region: 'ap-northeast-1', count: @num_instances },
  { region: 'sa-east-1', count: @num_instances } ]


### Methods
def finished(run_status)
  puts "EC2 Instances deleted:\n#{@finished_instances.to_json}"
  puts "Security Groups deleted:\n#{@finished_sgs.to_json}"
  puts "\nCompleted: #{run_status}"
end


### Script
if ARGV.empty?
  puts "Error: Please provide the multiregion JSON file as a command line argument - e.g. "
  puts " ruby delete-ec2-multiregion.rb multiregion-20150722171010.tmp"
  exit
end
filename = ARGV[0]

settings = OpenStruct.new YAML::load_file(File.join(__dir__, authfile))

ENV['AWS_SECRET_KEY_ID'] = settings[:AWS_ACCESS_KEY_ID]
ENV['AWS_SECRET_ACCESS_KEY'] = settings[:AWS_SECRET_ACCESS_KEY]

resources = JSON.parse( File.read(filename) )
@instances = resources['instances']
@sgs = resources['security_groups']
puts "Deleting (#{@instances.count}) EC2 instances.  Ctrl+C to cancel....\n\n"

@finished_instances = []
@finished_sgs = []

@instances.each do |i|
  ec2 = Aws::EC2::Client.new(region: i['region'])
  begin
    resp = ec2.terminate_instances( instance_ids: [ i['instance_id'] ] )
    instance_status = resp.to_hash[:terminating_instances][0][:current_state][:name]
    puts "#{i['region']}: EC2 instance #{i['instance_id']} is #{instance_status}"
    @finished_instances.push(i)

  rescue => e
      puts "EC2 Instance terminate failed for region: #{i[:region]} - (#{e.message})"
      puts e.backtrace.join("\n")
      finished("Error")
      exit
  end
end

puts "\nSleeping for 45 seconds to wait for SG dependencies."
sleep 45

@sgs.each do |sg|
  ec2 = Aws::EC2::Client.new(region: sg['region'])
  begin
    resp = ec2.delete_security_group( group_id: sg['security_group_id'] )
    puts "#{sg['region']}: EC2 SG #{sg['security_group_id']} is deleted."
    @finished_sgs.push(sg)

  rescue => e
      puts "EC2 SG deletion failed for region: #{sg[:region]} - (#{e.message})"
      puts e.backtrace.join("\n")
      finished("Error")
      exit
  end
end

finished("Success")
