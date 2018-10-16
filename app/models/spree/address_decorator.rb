Spree::Address.class_eval do
  has_one :enterprise
  belongs_to :country, class_name: "Spree::Country"

  after_save :touch_enterprise

  geocoded_by :geocode_address

  delegate :name, :to => :state, :prefix => true, :allow_nil => true

  def geocode_address
    geocode_address = [address1, address2, zipcode, city, country.andand.name, state.andand.name]
    filtered_address = geocode_address.select{ |field| !field.nil? && field != '' }
    filtered_address.compact.join(', ')
  end

  def full_address
    full_address = [address1, address2, city, zipcode, state.andand.name]
    filtered_address = full_address.select{ |field| !field.nil? && field != '' }
    filtered_address.compact.join(', ')
  end

  def address_part1
    address_part1 = [address1, address2]
    filtered_address = address_part1.select{ |field| !field.nil? && field != '' }
    filtered_address.compact.join(', ')
  end

  def address_part2
    address_part2= [city, zipcode, state.andand.name]
    filtered_address = address_part2.select{ |field| !field.nil? && field != '' }
    filtered_address.compact.join(', ')
  end

  private

  def touch_enterprise
    enterprise.andand.touch
  end
end
