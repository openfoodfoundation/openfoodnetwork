attributes :id, :name, :description, :long_description, :website, :instagram, :facebook, :linkedin, :twitter

node :promo_image do |producer| 
  producer.promo_image.url 
end
