# 1. Parse http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
# 2. Crawl domains
# 3. ???
# 4. Profit!
#
# Requires ccsv: http://github.com/fauna/ccsv/tree/master
#
# TODO:
#  - batching so we can start/stop
#  - grab top sites CSV automagically
#  - emulate a real browser so we get 'proper' results
#  - fetch redirects to /foo properly (do in Request block, should be able to send UA header too)
#74 dailymotion.com
#Exception:
#--- !ruby/exception:NoMethodError 
#message: "undefined method `request_uri' for #<URI::Generic:0x976148 URL:/en>"
#  - fix this 
# checking 97 nasza-klasa.pl
# doit.rb:73: undefined method `[]=' for nil:NilClass (NoMethodError)
#	from doit.rb:66:in `foreach'
#	from doit.rb:66
#  (something to do with the dash???)
#

top_sites_file = "top-1m.csv"
user_agent = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-GB; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2"

require 'rubygems'
require 'ccsv'
require 'net/http'
require 'yaml'

start_date = DateTime.now
results_filename = "tmp/results-#{start_date.strftime("%Y%m")}"


def fetch(uri, limit = 10)

    uri = URI.parse uri

    if limit == 0
	{:uri => uri.to_s, :message => "Reached redirect limit"}
    end

    begin

	response = Net::HTTP.get_response uri

	ret = {
	    :uri => uri.to_s,
	    :code => response.code,
	    :headers => response.header.to_hash, 
	    :http_version => response.http_version,
	    :message => response.message
	}

	case response
	when Net::HTTPSuccess     then ret
	when Net::HTTPRedirection then fetch(response['location'], limit - 1)
	end

	rescue => e
	    puts 'Exception:'
	    puts YAML::dump(e)
	    {:uri => uri.to_s, :message => "Exception: #{e.message}"}
	    
	rescue Timeout::Error => e
	    puts 'Timeout error:'
	    puts YAML::dump(e)
	    {:uri => uri.to_s, :message => "Timeout error: #{e.message}"}

    end

end


Ccsv.foreach(top_sites_file) do |values|
	domain = values[1]

	puts "checking #{values[0]} #{domain}"

	uri = "http://#{domain}/"
	response = fetch(uri)
	response[:domain] = domain
#puts YAML::dump(response)
	fd = File.open(results_filename, "a")
	fd.write YAML::dump(response)
	fd.close
    break if values[0].to_i == 5000

end

end_date = DateTime.now

puts "Start date: #{start_date}"
puts "End date: #{end_date}"

