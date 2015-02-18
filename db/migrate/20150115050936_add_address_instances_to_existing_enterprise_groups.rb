class AddAddressInstancesToExistingEnterpriseGroups < ActiveRecord::Migration
  def change
    country = Spree::Country.find_by_name(ENV['DEFAULT_COUNTRY'])
    state = country.states.first
    EnterpriseGroup.all.each do |g|
      next if g.address.present?
      address = Spree::Address.new(firstname: 'unused', lastname: 'unused', address1: 'undefined', city: 'undefined', zipcode: 'undefined', state: state, country: country, phone: 'undefined')
      g.address = address
      g.save
    end
  end
end
