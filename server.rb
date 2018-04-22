require 'sinatra'
require 'http'
require 'digest'

get '/ifttt/v1/status' do
  halt 401 unless request.env.fetch('HTTP_IFTTT_CHANNEL_KEY') == ENV.fetch("IFFT_SERVICE_KEY")

  { status: "OK" }.to_json
end

post '/ifttt/v1/test/setup' do
  halt 401 unless request.env.fetch('HTTP_IFTTT_CHANNEL_KEY') == ENV.fetch("IFFT_SERVICE_KEY")

  {
    "data": {
      "samples": {
        "triggers": {
          "search-trigger": {
            "keywords": "what then"
          }
        }
      }
    }
  }.to_json
end

post '/ifttt/v1/triggers/search-trigger' do
  # halt 401 unless request.env.fetch('HTTP_IFTTT_CHANNEL_KEY') == ENV.fetch("IFFT_SERVICE_KEY")

  data = JSON.parse(request.body.read)
  keywords = data["triggerFields"]["keywords"]
  response = JSON.parse(HTTP.get("https://www.gov.uk/api/search.json", params: { q: keywords, order: '-public_timestamp', fields: %w[public_timestamp link title]}))

  puts "Search response: #{response}"

  entries = response["results"].map do |result|
    public_timestamp = Time.parse(result["public_timestamp"])

    {
      title: result["title"],
      url: result["link"],
      created_at: public_timestamp,
      meta: {
        id: Digest::MD5.hexdigest(result["public_timestamp"]),
        timestamp: public_timestamp.to_i,
      }
    }
  end

  { data: entries }.to_json
end
