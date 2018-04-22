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
          },
          "registers": {
            "register": "country"
          }
        }
      }
    }
  }.to_json
end

# https://platform.ifttt.com/docs/api_reference
post '/ifttt/v1/triggers/search-trigger' do
  halt 401, { errors: [ { message: "Wrong channel key" }] }.to_json unless request.env.fetch('HTTP_IFTTT_CHANNEL_KEY') == ENV.fetch("IFFT_SERVICE_KEY")

  data = JSON.parse(request.body.read)
  keywords = data.dig("triggerFields", "keywords")

  halt 400, { errors: [ { message: "There weren't any keywords!" }] }.to_json unless keywords

  search_params = {
    count: data["limit"] || 50,
    order: '-public_timestamp',
    fields: %w[public_timestamp link title]
  }

  unless keywords == ""
    search_params.merge!(q: keywords)
  end

  response = JSON.parse(HTTP.get("https://www.gov.uk/api/search.json", params: search_params))

  entries = response["results"].map do |result|
    public_timestamp = Time.parse(result["public_timestamp"])

    {
      title: result["title"],
      url: "https://www.gov.uk#{result["link"]}",
      created_at: public_timestamp.iso8601,
      meta: {
        id: Digest::MD5.hexdigest(result["public_timestamp"]),
        timestamp: public_timestamp.to_i,
      }
    }
  end

  { data: entries }.to_json
end

post '/ifttt/v1/triggers/registers/fields/register/options' do
  halt 401, { errors: [ { message: "Wrong channel key" }] }.to_json unless request.env.fetch('HTTP_IFTTT_CHANNEL_KEY') == ENV.fetch("IFFT_SERVICE_KEY")

  response = JSON.parse(HTTP.get('https://register.register.gov.uk/records.json'))

  label_and_values = response.each do |register_id, info|
    { label: info["item"]["text"], value: register_id }
  end

  { data: label_and_values }.to_json
end

post '/ifttt/v1/triggers/registers' do
  halt 401, { errors: [ { message: "Wrong channel key" }] }.to_json unless request.env.fetch('HTTP_IFTTT_CHANNEL_KEY') == ENV.fetch("IFFT_SERVICE_KEY")

  data = JSON.parse(request.body.read)
  register = data.dig("triggerFields", "register")

  halt 400, { errors: [ { message: "Register not specified" }] }.to_json unless register

  entries = []
  { data: entries }.to_json
end
