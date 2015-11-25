# Grab a single file from github
# Requires a token - go here: https://github.com/settings/tokens

require 'rest_client'

# Parameters
GH_HOST = "api.github.com"
GH_TOKEN = "your_token"
GH_REPO = "adampats/ruby"
REPO_FILE = "fetch_github_file.rb"
OUT_FILE = "fetch_github_file.rb_deleteme"

# Script
gh_url = "https://#{GH_HOST}/repos/#{GH_REPO}/contents/#{REPO_FILE}"
begin
  print "GET #{gh_url} ..."
  resp = RestClient.get( gh_url,
	  accept: 'application/vnd.github.v3.raw',
	  Authorization: "token #{GH_TOKEN}" )
  puts "Done"

  print "Writing to #{OUT_FILE}..."
  File.write( OUT_FILE, resp )
  puts "Done"
rescue => e
  puts "Oh noes! An error: #{e.message}"
end
