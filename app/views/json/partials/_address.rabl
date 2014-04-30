attributes :city, :zipcode
node :state do |address|
  address.state.abbr
end
