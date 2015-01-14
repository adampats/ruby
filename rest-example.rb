require "rest-client"

host = 'http://localhost:3000' # The TAIL host
apikey = 'e6885f3eaee82bf' # Your admin API key from the TAIL UI
change = 'Notes'  # the field to be changed
change_to = 'Notes field changes' # the new value

servers = %w(
  lx00009.contoso.com
  lx00010.contoso.com
  lx00011.contoso.com
  lx000AA.contoso.com
)

url = "#{host}/api/doc"
auth_header = "Token token=#{apikey}"

servers.each do |server|
  begin
    uri = "#{url}/#{server}"
    action = "Retrieve #{server}"
    resource = RestClient.get uri, 'Authorization' => auth_header
    hash = JSON.parse(resource)
    hash[change] = change_to
    action = "Write #{server}"
    response = RestClient.put url, hash.to_json, 'Authorization' => auth_header,
      :content_type => :json
    puts action
    case response.code
    when 202
      p 'Accepted'
    else
      p response.code
    end
  rescue => e
    puts action
    puts "#{e.response.code} #{e.response}"
  end
end