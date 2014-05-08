collection @producers
extends 'json/enterprises'

node :path do |producer|
  producer_path(producer) 
end

node :hash do |producer|
  producer.to_param
end
