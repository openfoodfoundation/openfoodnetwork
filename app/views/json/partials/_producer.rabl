child distributors: :hubs do
  attributes :id
end
node :path do |producer|
  main_app.producer_path(producer) 
end

child supplied_taxons: :supplied_taxons do
  extends 'json/taxon'
end
