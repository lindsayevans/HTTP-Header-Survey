require 'yaml'

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

def print_results f

File.open(f) do |yf|
    YAML.load_documents(yf) do |ydoc|
	count_occurrences ydoc, :redirects
	count_occurrences ydoc, :code
	count_occurrences ydoc, :message
	count_occurrences ydoc, :use_ssl
	count_occurrences ydoc, :http_version
	count_occurrences ydoc, :port

	if ydoc.has_key? :headers
	    count_header ydoc[:headers], 'x-powered-by'
	    #count_header ydoc[:headers], 'server'
	end
    end
end

puts "*" * 80
puts "File: #{f}"
puts "Counts:"
puts YAML::dump(@counts)

end

print_results 'results/results-200911'
@counts = {}

print_results 'results/results-200912'
