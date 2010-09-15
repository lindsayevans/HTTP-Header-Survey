
# HTTP Header Survey

1. Parse http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
2. Crawl domains
3. ???
4. Profit!

Requires ccsv: http://github.com/fauna/ccsv/tree/master

## TODO
- batching so we can start/stop
- retry failed connections (count failures, keep looping til zero - with a retry limit; possibly try 'www.' if fail)
- constantise various bits

