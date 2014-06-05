collection @enterprises
extends 'json/enterprises'
attributes :latitude, :longitude

node :icon do |e|
  if e.is_primary_producer?
    image_path "map-icon-producer.svg"
  else
    image_path "map-icon-hub.svg"
  end
end
