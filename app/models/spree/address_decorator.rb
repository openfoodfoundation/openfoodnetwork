require 'open_food_web/notify_invalid_address_save'

Spree::Address.class_eval do
  has_one :enterprise

  geocoded_by :full_address
  after_validation :geocode

  delegate :name, :to => :state, :prefix => true, :allow_nil => true

  def full_address
    full_address = [address1, address2, zipcode, city, country.andand.name, state.andand.name]
    filtered_address = full_address.select{ |field| !field.nil? && field != '' }
    filtered_address.compact.join(', ')
  end
end
