require 'sinatra'

get '/maps' do
  file_path = File.join(File.dirname(__FILE__), 'maps.googleapis.js')

  content_type 'text/javascript'
  status 200
  IO.read(file_path)
end
