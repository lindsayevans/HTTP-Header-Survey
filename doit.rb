# 1. Parse http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
# 2. Crawl domains
# 3. ???
# 4. Profit!
#
# Requires ccsv: http://github.com/fauna/ccsv/tree/master
#
# TODO:
#  - grab top sites CSV automagically
#  - follow redirects
#  - emulate a real browser so we get 'proper' results
#

top_sites_file = "top-1m.csv"

require 'rubygems'
require 'ccsv'
require 'net/http'
require 'yaml'

date = DateTime.now
results_filename = "results-#{date.strftime("%Y%m")}"

Ccsv.foreach(top_sites_file) do |values|
    domain = values[1]

    puts "checking #{values[0]} #{domain}"

    uri = URI.parse "http://#{domain}/"
    response = Net::HTTP.get_response uri

    fd = File.open(results_filename, "a")
    fd.write YAML::dump(response)

#    break if values[0].to_i > 3

end


