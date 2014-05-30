collection @producers
extends 'json/enterprises'

child supplied_taxons: :taxons do
  extends 'json/taxon'
end

child distributors: :distributors do
  attributes :name, :id
  node :path do |distributor|
    shop_enterprise_path(distributor) 
  end
end

node :path do |producer|
  producer_path(producer) 
end

node :hash do |producer|
  producer.to_param
end
