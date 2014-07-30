attributes :city, :zipcode, :phone
node :state_name do |address|
  address.state.abbr
end
