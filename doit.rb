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
#  - follow redirects
#  - emulate a real browser so we get 'proper' results
#

top_sites_file = "top-1m.csv"

require 'rubygems'
require 'ccsv'
require 'net/http'
require 'yaml'

start_date = DateTime.now
results_filename = "results-#{start_date.strftime("%Y%m")}"


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
    break if values[0].to_i > 1

end

end_date = DateTime.now

puts "Start date: #{start_date}"
puts "End date: #{end_date}"

