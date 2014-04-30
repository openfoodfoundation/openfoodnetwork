collection @producers
attributes :name, :id

node :path do |producer|
  producer_path(producer) 
end
