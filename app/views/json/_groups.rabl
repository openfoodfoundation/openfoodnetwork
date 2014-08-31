collection @groups
attributes :id, :name, :position, :description, :long_description

child enterprises: :enterprises do
  attributes :id
end

node :logo do |group|
  group.logo(:medium) if group.logo.exists?
end

node :promo_image do |group|
  group.promo_image(:large) if group.promo_image.exists?
end
