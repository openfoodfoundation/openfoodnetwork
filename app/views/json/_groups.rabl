collection @groups
attributes :id, :name, :position, :description, :long_description

child enterprises: :enterprises do
  extends 'json/enterprises'
end

node :logo do |group|
  group.logo(:original)
end
