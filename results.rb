require 'yaml'
require 'rubygems'
require 'faster_csv'
require 'activesupport'

@counts = {}


def count_occurrences ydoc, sym
    if ydoc.has_key? sym
	@counts[sym] = {} if !@counts.has_key? sym
	@counts[sym][ydoc[sym]] = @counts[sym].has_key?(ydoc[sym]) ? @counts[sym][ydoc[sym]] + 1 : 1
    end
end

def count_header ydoc, sym
    if ydoc.has_key? sym
	v = ydoc[sym][0]#.split(' ').first
	@counts[sym] = {} if !@counts.has_key? sym
	@counts[sym][v] = @counts[sym].has_key?(v) ? @counts[sym][v] + 1 : 1
    end
end


def count_server_header ydoc, sym
    if ydoc.has_key? sym
	v = ydoc[sym][0].split('/').first
	@counts[sym] = {} if !@counts.has_key? sym
	@counts[sym][v] = @counts[sym].has_key?(v) ? @counts[sym][v] + 1 : 1
    end
end

def print_results f

  props = ['message', 'code', 'domain', 'redirects', 'http_version', 'port', 'host', 'use_ssl', 'path','headers']
  headers = []
  csv = []

  File.open(f) do |yf|
    YAML.load_documents(yf) do |ydoc|
	#props.concat(ydoc.stringify_keys.keys)
	headers.concat(ydoc[:headers].keys) if ydoc.has_key? :headers
    end

    puts "*" * 80
    puts "Input file: #{f}"
    #puts props.uniq.concat(headers.uniq.sort).join(',')

    headers = headers.uniq.sort
    csv << props.uniq.concat(headers)

  end

  File.open(f) do |yf|

    YAML.load_documents(yf) do |ydoc|

      data = [
	ydoc[:message],	ydoc[:code], ydoc[:domain], ydoc[:redirects], ydoc[:http_version], ydoc[:port], ydoc[:host], ydoc[:use_ssl], ydoc[:path], ydoc.has_key?(:headers) ? ydoc[:headers].length : 0
      ]

      headers.each do |h|
	if ydoc.has_key?(:headers) && ydoc[:headers].has_key?(h)
	  data.push(ydoc[:headers][h])
	else
	  data.push(nil)
	end
      end

      #puts data.join(',')

      csv << data
    end

  end

  FasterCSV.open("#{f.gsub('results/','results/csv/')}.csv", "w") do |c|
    csv.each do |r|
      c << r
    end
  end

  puts "Output file: #{f.gsub('results/','results/csv/')}.csv"

end

Dir.glob("results/results-*").each do |f|
  print_results f
  @counts = {}
end
