require 'sinatra'

get '/ifttt/v1/status' do
  halt 401 unless request.env.fetch('HTTP_IFTTT_CHANNEL_KEY') == ENV["IFFT_SERVICE_KEY"]

  { status: "OK" }.to_json
end

post '/ifttt/v1/test/setup' do
  halt 401 unless request.env.fetch('HTTP_IFTTT_CHANNEL_KEY') == ENV["IFFT_SERVICE_KEY"]

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
  halt 401 unless request.env.fetch('HTTP_IFTTT_CHANNEL_KEY') == ENV["IFFT_SERVICE_KEY"]

  entries = []

  {
    "data": entries,
  }.to_json
end
