class EnterpriseSerializer < ActiveModel::Serializer
  #attributes :name, :id, :description, :latitude, :longitude, 
    #:long_description, :website, :instagram, :linkedin, :twitter, 
    #:facebook, :is_primary_producer, :is_distributor, :phone

  has_many :distributed_taxons, root: :taxons, serializer: Spree::DistributedTaxonSerializer
end
