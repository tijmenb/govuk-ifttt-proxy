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
          },
          "companies": {
            "company_number": "09426399"
          },
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

  label_and_values = response.map do |register_id, info|
    { label: info["item"][0]["text"], value: register_id }
  end

  { data: label_and_values }.to_json
end

post '/ifttt/v1/triggers/registers' do
  halt 401, { errors: [ { message: "Wrong channel key" }] }.to_json unless request.env.fetch('HTTP_IFTTT_CHANNEL_KEY') == ENV.fetch("IFFT_SERVICE_KEY")

  data = JSON.parse(request.body.read)
  register_id = data.dig("triggerFields", "register")

  halt 400, { errors: [ { message: "Register not specified" }] }.to_json unless register_id

  register_data = JSON.parse(HTTP.get("https://#{register_id}.register.gov.uk/register"))
  register_name = register_data["register-record"]["text"]

  # This will stop working once there are more than 5000 entries in a register
  response = JSON.parse(HTTP.get("https://#{register_id}.register.gov.uk/entries.json?limit=5000"))

  entries = response.reverse.first(data["limit"] || 50).map do |entry|
    {
      updated_record: "https://#{register_id}.register.gov.uk/record/#{entry["key"]}",
      register_name: register_name,
      meta: {
        id: entry["index-entry-number"],
        timestamp: Time.parse(entry["entry-timestamp"]).to_i,
      }
    }
  end

  { data: entries }.to_json
end

post '/ifttt/v1/triggers/companies' do
  halt 401, { errors: [ { message: "Wrong channel key" }] }.to_json unless request.env.fetch('HTTP_IFTTT_CHANNEL_KEY') == ENV.fetch("IFFT_SERVICE_KEY")

  data = JSON.parse(request.body.read)
  company_number = data.dig("triggerFields", "company_number")

  halt 400, { errors: [ { message: "Company number not specified" }] }.to_json unless company_number

  response = JSON.parse(HTTP.auth(ENV.fetch("COMPANIES_HOUSE_API_KEY")).get("https://api.companieshouse.gov.uk/company/#{company_number}/filing-history"))

  entries = response["items"].first(data["limit"] || 50).map do |entry|
    {
      summary: entry["description"],
      company_url: "https://beta.companieshouse.gov.uk/company/#{company_number}",
      meta: {
        id: entry["transaction_id"],
        timestamp: Time.parse(entry["date"]).to_i,
      }
    }
  end

  { data: entries }.to_json
end
