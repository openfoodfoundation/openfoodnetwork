attributes :city, :zipcode, :phone
node :state do |address|
  address.state.abbr
end
