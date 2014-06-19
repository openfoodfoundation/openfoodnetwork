child supplied_taxons: :taxons do
  extends 'json/taxon'
end
child distributors: :hubs do
  attributes :id
end
node :path do |producer|
  producer_path(producer) 
end
