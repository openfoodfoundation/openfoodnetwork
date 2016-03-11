attributes :name, :id, :description, :latitude, :longitude, :long_description, :website, :instagram, :linkedin, :twitter, :facebook, :is_primary_producer, :is_distributor, :phone

node :email_address do |enterprise|
  enterprise.email_address.to_s.reverse
end

child :address do
  extends "json/partials/address"
end

node :hash do |enterprise|
  enterprise.to_param
end

node :logo do |enterprise|
  enterprise.logo(:medium) if enterprise.logo?
end

node :promo_image do |enterprise|
  enterprise.promo_image(:large) if enterprise.promo_image?
end

node :icon do |e|
  if e.is_primary_producer and e.is_distributor
    image_path "map_003-producer-shop.svg"
  elsif e.is_primary_producer
    image_path "map_001-producer-only.svg"
  else
    image_path "map_005-hub.svg"
  end
end
