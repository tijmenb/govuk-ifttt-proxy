require 'sinatra'

get '/ifttt/v1/status' do
  halt 401 unless request['IFTTT-Channel-Key'] == ENV["IFFT_SERVICE_KEY"]

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
