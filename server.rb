require 'sinatra'

get '/ifttt/v1/status' do
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
