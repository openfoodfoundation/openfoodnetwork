attributes :name, :id, :description, :long_description

node :promo_image do |producer| 
  producer.promo_image.url 
end
