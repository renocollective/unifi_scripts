require "faraday"
require "faraday_middleware"
require "faraday-cookie_jar"
require "fileutils"
require "multi_json"

USER     = ENV.fetch("UNIFI_USER").freeze
PASS     = ENV.fetch("UNIFI_PASS").freeze
SERVER   = ENV.fetch("UNIFI_SERVER").freeze
BASE_URL = "/api/".freeze

AUTOMATIC_GROUP= { "_id" => "automatic", "name" => "Automatic" }.freeze

DIR = File.expand_path File.dirname(__FILE__)

users_dir = FileUtils.mkdir_p(File.join(DIR, "users")).first

conn = Faraday.new(:url => "https://#{SERVER}#{BASE_URL}", :ssl => { :verify => false }) do |faraday|
  faraday.use :cookie_jar
  faraday.request  :url_encoded
  #  faraday.response :logger
  faraday.adapter  Faraday.default_adapter
  faraday.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
end

# login
conn.get "https://#{SERVER}/login?login=login&username=#{USER}&password=#{PASS}"

# get the groups
response = conn.post "list/usergroup" do |req|
  req.headers["Content-Type"] = "application/json"
  req.body = %|{}| # empty json body
end

groups = response.body["data"]

# Add the "Automatic" group
groups << AUTOMATIC_GROUP

# get the users
response = conn.post "stat/alluser" do |req|
  req.headers["Content-Type"] = "application/json"
  req.body = %|{"type":"all","is_offline":false,"within":"8760"}|
end

users = response.body["data"]

# sort em up good
users.sort_by!{ |user| user.fetch("hostname", "_nohostname_").downcase }

users.each do |user|
  mac_addr = user["mac"]
  filename = %|#{mac_addr.gsub(/\:/, "_")}.json|

  File.open(File.join(users_dir, filename), "w+") do |f|
    Hash.new.tap do |user_hash|
      user_hash["user"] = user

      # lookup the group - auto is the default
      group = groups.find(-> {AUTOMATIC_GROUP}) do |g|
        g["_id"] == user.fetch("usergroup_id") { "automatic" }
      end

      # add the group
      user_hash["user"]["usergroup"] = group

      f.puts MultiJson.dump(user_hash, pretty: true)
    end # user_hash
  end # user file
end # users
