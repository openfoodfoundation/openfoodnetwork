require "vcr"

VCR.configure do |c|
  c.cassette_library_dir = "spec/vcr"
  c.hook_into :webmock
  c.ignore_localhost = true
  c.ignore_hosts "chromedriver.storage.googleapis.com"
  c.allow_http_connections_when_no_cassette = true
end
