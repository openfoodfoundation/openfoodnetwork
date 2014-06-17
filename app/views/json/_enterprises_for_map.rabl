collection @enterprises
extends 'json/enterprises'
attributes :latitude, :longitude, :long_description, :website, :instagram, :linkedin, :twitter, :facebook, :is_primary_producer?, :is_distributor?

node :logo do |enterprise|
  enterprise.logo(:medium) if enterprise.logo.exists?
end

node :promo_image do |enterprise|
  enterprise.promo_image(:large) if enterprise.promo_image.exists?
end

node :active do |enterprise|
  @active_distributors.include?(enterprise)
end

child distributors: :hubs do
  extends 'json/enterprises'
  node :active do |hub|
    @active_distributors.include?(hub)
  end
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
