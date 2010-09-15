# HTTP Header Survey
# Capturing HTTP responses from a bunch of the most popular websites
#
# Copyright Lindsay Evans (I'll think of a real licene to use one day)
# 

top_sites_file = "top-1m.csv"
maximum_domains = 1000
@timeout_limit = 300
#top_sites_file = "test.csv"
@user_agent = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-GB; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2"
@headers = {
    'User-Agent' => @user_agent,
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language' => 'en-gb,en;q=0.5',
    'Accept-Encoding' => 'gzip,deflate',
    'Accept-Charset:' => 'SO-8859-1,utf-8;q=0.7,*;q=0.7',
    'Keep-Alive' => '300',
    'Connection' => 'keep-alive'
}

require 'rubygems'
require 'ccsv'
require 'net/https'
require 'yaml'
require 'zip/zip'
require 'net/http'
require 'fileutils'


start_date = DateTime.now
results_filename = "tmp/results-#{start_date.strftime("%Y%m")}"

# Download zip
FileUtils.rm_f 'top-1m.csv.zip'
FileUtils.rm_f 'top-1m.csv'

puts 'Downloading zip...'
Net::HTTP.start('s3.amazonaws.com') { |http|
  resp = http.get('/alexa-static/top-1m.csv.zip')
  open('top-1m.csv.zip', 'wb') { |file|
    file.write(resp.body)
  }
}
puts 'Done.'
puts 'Unzipping...'


Zip::ZipFile.open('top-1m.csv.zip') { |zipfile|
  begin
    zipfile.extract('top-1m.csv', 'top-1m.csv')
  end
}
puts 'Done.'


def fetch(domain, path = '/', limit = 10)
    # Need to parse location here so we can do absolute or relative redirect
    uri = URI.parse path
    uri.host = domain if uri.host.nil?
    uri.path = path if uri.path.nil?
    uri.port = 80 if uri.port.nil?
    domain = uri.host
    path = uri.path
    path = uri.path + '?' + uri.query if !uri.query.nil?
    path = '/' if path.empty?

    if limit <= 0
	return {:domain => domain, :path => path, :message => "Reached redirect limit"}
    end

    begin
	http = Net::HTTP.new(domain, uri.port)
	http.use_ssl = uri.is_a? URI::HTTPS
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE if uri.is_a?(URI::HTTPS)
	http.open_timeout = @timeout_limit
	http.read_timeout = @timeout_limit
	http.timeout = @timeout_limit if uri.is_a? URI::HTTPS
	response = http.start {|http|
	    req = Net::HTTP::Get.new(path, @headers)
	    timeout(@timeout_limit + 1) {
		http.request(req)
	    }
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
	return {:path => path, :message => e.message, :code => "-1"}
    end

end

#fetch('www.delorie.com','http://www.delorie.com:81/some/url.txt')

threads = []

begin

Ccsv.foreach(top_sites_file) do |values|
    threads << Thread.new {
	domain = values[1]

	puts "checking #{values[0]} #{domain}"

	response = fetch(domain)
	response = {:path => "/", :message => "response is nil", :code => "-1"} if response.nil?
	response[:domain] = domain

	fd = File.open(results_filename, "a")
	fd.write YAML::dump(response)
	fd.close
    }
    break if values[0].to_i == maximum_domains

end
threads.each { |t|  t.join }

rescue Exception => e
puts YAML::dump(e)
end

end_date = DateTime.now

puts "Start date: #{start_date}"
puts "End date: #{end_date}"

