collection @suburbs
attributes :id
node(:label) { |suburb| "#{suburb.name} (#{suburb.state_name}), #{suburb.postcode}" }