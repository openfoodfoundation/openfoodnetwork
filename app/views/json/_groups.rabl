collection @groups
attributes :id, :permalink, :name, :position, :description, :long_description, :email, :website, :facebook, :instagram, :linkedin, :twitter

child enterprises: :enterprises do
  attributes :id
end

node :logo do |group|
  group.logo(:medium) if group.logo?
end

node :promo_image do |group|
  group.promo_image(:large) if group.promo_image?
end

node :state do |group|
  group.state().andand.abbr
end
