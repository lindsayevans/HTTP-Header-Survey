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
#  - threading, so it won't take 22 days to do the whole lot
#  - retry failed connections (count failures, keep looping til zero - with a retry limit)
#  - constantise various bits
#  - support HTTPS & different ports (need for blogger.com)
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

    # Need to parse location here so we can do absolute or relative redirect
    uri = URI.parse path
    uri.host = domain if uri.host.nil?
    uri.path = path if uri.path.nil?
    domain = uri.host
    path = uri.path
    @ssl = uri.is_a? URI::HTTPS

    if limit == 0
	{:domain => domain, :path => path, :message => "Reached redirect limit"}
    end

    begin
	http = Net::HTTP.new(domain, uri.port)
	http.use_ssl = uri.is_a? URI::HTTPS
	response = http.start {|http|
	    req = Net::HTTP::Get.new(path, 'User-Agent' => @user_agent)
	    http.request(req)
	}
	 Net::HTTP.finish
	ret = {
	    :domain => domain, :path => path,
	    :code => response.code,
	    :headers => response.header.to_hash, 
	    :http_version => response.http_version,
	    :message => response.message
	}

	case response
	when Net::HTTPSuccess     then ret
	when Net::HTTPRedirection then fetch(domain, response['location'], limit - 1)
	end
    end

end


Ccsv.foreach(top_sites_file) do |values|
    domain = values[1]

    puts "checking #{values[0]} #{domain}"

    response = fetch(domain)

    fd = File.open(results_filename, "a")
    fd.write YAML::dump(response)
    fd.close
    break if values[0].to_i == 7#5000

end

end_date = DateTime.now

puts "Start date: #{start_date}"
puts "End date: #{end_date}"

