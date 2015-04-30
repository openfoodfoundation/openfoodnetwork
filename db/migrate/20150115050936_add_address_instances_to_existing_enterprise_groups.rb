class AddAddressInstancesToExistingEnterpriseGroups < ActiveRecord::Migration
  def change
    country = Spree::Country.find_by_iso(ENV['DEFAULT_COUNTRY_CODE'])
    state = country.states.first
    EnterpriseGroup.all.each do |g|
      next if g.address.present?
      address = Spree::Address.new(firstname: 'unused', lastname: 'unused', address1: 'undefined', city: 'undefined', zipcode: 'undefined', state: state, country: country, phone: 'undefined')
      g.address = address
      # some groups are invalid, because of a missing description
      g.save!(validate: false)
    end
  end

  def self.down
    # we can't know which addresses were already there and which weren't
    # and we can't remove addresses as long as they are referenced and
    # required by the model
  end
end
