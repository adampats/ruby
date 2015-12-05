# Creates a GitHub repository using the v3 API.  Because using the Web GUI is fo suckas.
# https://developer.github.com/v3/repos/#create

require 'rest_client'

# TODO: make this use user's .git config somehow?
GH_USER = "adampats"
gh_token = "" # Generate a token here: https://github.com/settings/tokens

if ARGV[0].nil?
  puts "Please pass the name of the new repo you want as ARGV[0] !"
  exit
end
repo = ARGV[0]

if gh_token.empty?
  puts "Enter a GitHub token please: "
  gh_token = STDIN.gets.chomp
end

begin
  resp = RestClient.post(
    "https://#{GH_USER}:#{gh_token}@api.github.com/user/repos",
    { "name" => repo }.to_json,
    :content_type => :json,
    :accept => :json)

  if resp.code == 201
    puts "Success. #{GH_USER}/#{repo} created successfully."
  end

rescue Exception => e
  puts "Error."
  puts e.message
  puts e.backtrace.inspect
end

puts "Done."
