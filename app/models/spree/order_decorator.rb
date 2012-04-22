Spree::Order.class_eval do
  attr_accessible :distributor_id

  belongs_to :distributor

  before_validation :shipping_address_from_distributor

  private
  def shipping_address_from_distributor
    if distributor
      ship_address.firstname = bill_address.firstname
      ship_address.lastname = bill_address.lastname
      ship_address.phone = bill_address.phone

      ship_address.address1 = distributor.pickup_address
      ship_address.city = distributor.city
      ship_address.zipcode = distributor.post_code
      ship_address.state = distributor.state
      ship_address.country_id = distributor.country_id
    end
  end
end
