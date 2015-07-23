# Run EC2 instances in multiple regions
# Parameters:
# ...
#
# Requires AWS IAM access keys be configured in aws.local.yml

require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'
require 'uuid'
require 'pry-byebug'
require 'json'
require 'base64'

### Parameters
authfile = 'aws.local.yml'
@key = 'adam'
@image_name = 'ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-20150325'
@user_data = '' # do no base64 encode
@instance_type = 't2.micro'
@inbound_tcp_ports = [ 22 ]
@tags = [ { key: "app", value: "AP Test" } ]
@num_instances = 20
@regions = [
 { region: 'us-east-1', count: @num_instances },
 { region: 'us-west-2', count: @num_instances },
 { region: 'us-west-1', count: @num_instances },
 { region: 'eu-west-1', count: @num_instances },
 { region: 'eu-central-1', count: 10 },
 { region: 'ap-southeast-1', count: @num_instances },
 { region: 'ap-southeast-2', count: @num_instances },
 { region: 'ap-northeast-1', count: @num_instances },
 { region: 'sa-east-1', count: @num_instances } ]


### Methods
def finished(run_status)
  timestamp = Time.now.localtime.strftime("%Y%m%d%H%M%S")
  output = { instances: @deployed_instances, security_groups: @deployed_sgs }
  output_file = "multiregion-#{timestamp}.tmp"

  puts "(#{@deployed_sgs.count}) Security Groups created.\n"
  puts "(#{@deployed_instances.count}) EC2 Instances created.\n"

  File.open(output_file, 'w') { |file| file.write( output.to_json ) }
  puts "Output file: #{output_file}"
  puts "\nCompleted: #{run_status}"
end


### Script
settings = OpenStruct.new YAML::load_file(File.join(__dir__, authfile))

ENV['AWS_SECRET_KEY_ID'] = settings[:AWS_ACCESS_KEY_ID]
ENV['AWS_SECRET_ACCESS_KEY'] = settings[:AWS_SECRET_ACCESS_KEY]

instance_total_count = @regions.map { |h| h[:count] }.inject(:+)
puts "Deploying (#{instance_total_count}) EC2 instances ...  Ctrl+C to cancel....\n\n"

@deployed_sgs = []
@deployed_instances = []

@regions.each do |r|
  ec2 = Aws::EC2::Client.new(region: r[:region])
  begin
    sg_resp = ec2.create_security_group(
      group_name: "tcp-#{@inbound_tcp_ports}-inbound",
      description: "TCP Inbound #{@inbound_tcp_ports}" )
    @sg_id = sg_resp.to_hash[:group_id]
    sleep 2
    ec2.create_tags( resources: [ @sg_id ], tags: @tags )
    @inbound_tcp_ports.each do |port|
      sg_resp = ec2.authorize_security_group_ingress(
        group_id: @sg_id,
        ip_protocol: "tcp",
        from_port: port,
        to_port: port,
        cidr_ip: "0.0.0.0/0" )
    end
    @deployed_sgs.push( { region: r[:region], security_group_id: @sg_id } )
    puts "#{r[:region]}: created EC2 SG:  #{@sg_id}"

  rescue => e
      puts "EC2 Security Group creation failed for region: #{r[:region]} - (#{e.message})"
      puts e.backtrace.join("\n")
      finished("Error")
      exit
  end

  begin
    image_resp = ec2.describe_images( filters: [ {name: "name", values: ["#{@image_name}"]} ] )
    image_id = image_resp[:images][0][:image_id]

    run_resp = ec2.run_instances( image_id: image_id,
      min_count: r[:count],
      max_count: r[:count],
      key_name: @key,
      security_group_ids: [@sg_id],
      user_data: Base64.strict_encode64( @user_data ),
      instance_type: @instance_type )
    sleep 5

    run_resp.to_hash[:instances].each do |instance|
      ec2.create_tags( resources: [ instance[:instance_id] ], tags: @tags )
      new_instance = ec2.describe_instances( instance_ids: [ instance[:instance_id] ])
      public_dns = new_instance.to_hash[:reservations][0][:instances][0][:public_dns_name]
      @deployed_instances.push({
        region: r[:region],
        instance_id: instance[:instance_id],
        instance_hostname: public_dns })
      puts "#{r[:region]}: created EC2 instance:  #{instance[:instance_id]}"
    end

  rescue => e
    puts "EC2 instance creation failed - (#{e.message})"
    puts e.backtrace.join("\n")
    finished("Error")
    exit
  end

end

finished("Success")
