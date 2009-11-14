# HTTP Header Survey
# Capturing HTTP responses from a bunch of the most popular websites
#
# Copyright Lindsay Evans (I'll think of a real licene to use one day)
# 

top_sites_file = "top-1m.csv"
#top_sites_file = "test.csv"
@user_agent = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-GB; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2"

require 'rubygems'
require 'ccsv'
require 'net/https'
require 'yaml'
require 'ThreadPool'

start_date = DateTime.now
results_filename = "tmp/results-#{start_date.strftime("%Y%m")}"


def fetch(domain, path = '/', limit = 10)

    # Need to parse location here so we can do absolute or relative redirect
    uri = URI.parse path
    uri.host = domain if uri.host.nil?
    uri.path = path if uri.path.nil?
    domain = uri.host
    path = uri.path
    path = '/' if path.empty?

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
	ret = {
	    :host => domain, :path => path,
	    :port => uri.port, :use_ssl => http.use_ssl,
	    :redirects => 10 - limit,
	    :code => response.code,
	    :headers => response.header.to_hash, 
	    :http_version => response.http_version,
	    :message => response.message
	}

	case response
	    when Net::HTTPSuccess     then ret
	    when Net::HTTPRedirection then fetch(domain, response['location'], limit - 1)
	end

    rescue Exception => e
	{:domain => domain, :path => path, :message => e.message}
    end

end

threads = []

Ccsv.foreach(top_sites_file) do |values|

    threads << Thread.new {
	domain = values[1]

	puts "checking #{values[0]} #{domain}"

	response = fetch(domain)
	response[:domain] = domain

	fd = File.open(results_filename, "a")
	fd.write YAML::dump(response)
	fd.close
    }
    break if values[0].to_i == 5000

end
threads.each { |t|  t.join }

end_date = DateTime.now

puts "Start date: #{start_date}"
puts "End date: #{end_date}"

