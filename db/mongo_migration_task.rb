#frozen_string_literal: true
require 'mechanize'
require 'json'
require 'mongo'
require "dotenv"
Dotenv.load

class MongoMigrationTask
  def initialize
     @agent = Mechanize.new
     @db = Mongo::Client.new([ENV['MONGO_HOST']],:database =>ENV['MONGO_DB'].to_s)
     @coll = @db[ENV['MONGO_COL']]
     @key = ENV['API_KEY']
  end

  def run
    ('a'..'z').to_a.each do |keyword|
      page = @agent.get("https://api.themoviedb.org/3/search/movie?api_key=#{@key}&language=en-US&query=#{keyword}&page=1&include_adult=false")
      data  = JSON.parse(page.content.to_s)
      #Send to the records to the processor
      processor(data)
      total_pages =  data['total_pages']
      (2..total_pages).each do |page_no|
        page = @agent.get("https://api.themoviedb.org/3/search/movie?api_key=#{@key}&language=en-US&query=#{keyword}&page=#{page_no}&include_adult=false")
        data  = JSON.parse(page.content.to_s)
        sleep(rand(5))
        processor(data)
      end
    end
  end

  def processor(data)
    data['results'].each do  |records|
      if records.length > 0
        @coll.update_one({"poster_path" => records["poster_path"]}, {'$set' => records}, {:upsert=>true})
      end
    end
  end
end
