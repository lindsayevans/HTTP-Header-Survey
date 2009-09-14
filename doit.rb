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

Ccsv.foreach(top_sites_file) do |values|

    begin
	domain = values[1]

	puts "checking #{values[0]} #{domain}"

	uri = URI.parse "http://#{domain}/"
	response = Net::HTTP.get_response uri

	fd = File.open(results_filename, "a")
	fd.write YAML::dump({
	    :domain => domain,
	    :code => response.code,
	    :headers => response.header.to_hash, 
	    :http_version => response.http_version,
	    :message => response.message
	})
	#fd.write YAML::dump(response)
	rescue => e
	    puts 'Exception:'
	    puts YAML::dump(e)
	rescue Timeout::Error => e
	    puts 'Timeout error:'
	    puts YAML::dump(e)

    end
    #break if values[0].to_i > 1

end

end_date = DateTime.now

puts "Start date: #{start_date}"
puts "End date: #{end_date}"

