require 'sinatra'

get '/ifttt/v1/status' do
  halt 401 unless request.env.fetch('HTTP_IFTTT_CHANNEL_KEY') == ENV["IFFT_SERVICE_KEY"]

  {
    "data": {
      "samples": {
        "triggers": {
          "search-trigger": {
            "keywords": ""
          }
        }
      }
    }
  }.to_json
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
