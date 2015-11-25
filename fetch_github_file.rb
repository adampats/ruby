# Grab a single file from github
# Requires a token

require 'json'
require 'rest_client'
require 'pry-byebug'

# Parameters
GH_HOST = "github.com"
GH_TOKEN = "your_token"
GH_REPO = "adampats/ruby"
REPO_FILE = "fetch_github_file.rb"
OUT_FILE = "fetch_github_file.rb_deleteme"

# Script
gh_url = "https://#{GH_HOST}/api/v3/repos/#{GH_REPO}/contents/#{REPO_FILE}"
begin
  resp = RestClient.get( gh_url,
	 accept: 'application/vnd.github.v3.raw',
	  Authorization: "token #{GH_TOKEN}" )

  puts "Writing to #{OUT_FILE}..."
  File.write( OUT_FILE, resp )
rescue => e
  puts "Error: #{e.message}"
end

puts "Done."
