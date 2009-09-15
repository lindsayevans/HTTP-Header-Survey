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
#  - fix this 
# checking 97 nasza-klasa.pl
# doit.rb:73: undefined method `[]=' for nil:NilClass (NoMethodError)
#	from doit.rb:66:in `foreach'
#	from doit.rb:66
#  (something to do with the dash??? or maybe not...)
#

top_sites_file = "top-1m.csv"
#top_sites_file = "test.csv"
@user_agent = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-GB; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2"

require 'rubygems'
require 'ccsv'
require 'net/http'
require 'yaml'

start_date = DateTime.now
results_filename = "tmp/results-#{start_date.strftime("%Y%m")}"


def fetch(domain, path = '/', limit = 10)

    #uri = URI.parse uri
    
    if limit == 0
	{:domain => domain, :path => path, :message => "Reached redirect limit"}
    end

    begin

	Net::HTTP.start(domain) {|http|
	    req = Net::HTTP::Get.new(path, 'User-Agent' => @user_agent)
	    @response = http.request(req)
	}
	response = @response
	ret = {
	    :domain => domain, :path => path,
	    :code => response.code,
	    :headers => response.header.to_hash, 
	    :http_version => response.http_version,
	    :message => response.message
	}

	case response
	when Net::HTTPSuccess     then ret
	# TODO: Need to parse location here so we can do absolute or relative redirect
	when Net::HTTPRedirection then fetch(domain, response['location'], limit - 1)
	end

	rescue => e
	    puts 'Exception:'
	    puts YAML::dump(e)
	    {:domain => domain, :path => path, :message => "Exception: #{e.message}"}
	    
	rescue Timeout::Error => e
	    puts 'Timeout error:'
	    puts YAML::dump(e)
	    {:domain => domain, :path => path, :message => "Timeout error: #{e.message}"}

    end

end


Ccsv.foreach(top_sites_file) do |values|
    domain = values[1]

    puts "checking #{values[0]} #{domain}"

    response = fetch(domain)

    fd = File.open(results_filename, "a")
    fd.write YAML::dump(response)
    fd.close
    break if values[0].to_i == 5000

end

end_date = DateTime.now

puts "Start date: #{start_date}"
puts "End date: #{end_date}"

