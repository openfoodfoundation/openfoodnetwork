attributes :name, :id, :description, :latitude, :longitude, :long_description, :website, :instagram, :linkedin, :twitter, :facebook, :is_primary_producer, :is_distributor

node :email do |enterprise|
  enterprise.email.to_s.reverse
end

child :address do
  extends "json/partials/address"
end

node :hash do |enterprise|
  enterprise.to_param
end

node :logo do |enterprise|
  enterprise.logo(:medium) if enterprise.logo.exists?
end

node :promo_image do |enterprise|
  enterprise.promo_image(:large) if enterprise.promo_image.exists?
end

node :icon do |e|
  if e.is_primary_producer? and e.is_distributor?
    image_path "map-icon-both.svg"
  elsif e.is_primary_producer?
    image_path "map-icon-producer.svg"
  else
    image_path "map-icon-hub.svg"
  end
end
