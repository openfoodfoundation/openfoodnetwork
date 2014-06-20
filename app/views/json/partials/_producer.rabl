child supplied_taxons: :taxons do
  extends 'json/taxon'
end
child distributors: :hubs do
  attributes :id
end
node :path do |producer|
  main_app.producer_path(producer) 
end
