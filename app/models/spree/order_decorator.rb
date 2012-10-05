Spree::Order.class_eval do
  belongs_to :distributor

  before_validation :shipping_address_from_distributor
  after_create :set_default_shipping_method


  def can_change_distributor?
    # Distributor may not be changed once an item has been added to the cart/order
    line_items.empty?
  end

  def distributor=(distributor)
    raise "You cannot change the distributor of an order with products" unless distributor == self.distributor || can_change_distributor?
    super(distributor)
  end

  def can_add_product_to_cart?(product)
    can_change_distributor? || product.distributors.include?(distributor)
  end

  def set_variant_attributes(variant, attributes)
    line_item = contains?(variant)

    if attributes.key?(:max_quantity) && attributes[:max_quantity].to_i < line_item.quantity
      attributes[:max_quantity] = line_item.quantity
    end

    line_item.assign_attributes(attributes)
    line_item.save!
  end


  private

  # On creation of the order (when the first item is added to the user's cart), set the
  # shipping method to the first one available and create a shipment.
  # order.create_shipment! creates an adjustment for the shipping cost on the order,
  # which means that the customer can see their shipping cost at every step of the
  # checkout process, not just after the delivery step.
  # This is based on the assumption that there's only one shipping method visible to the user,
  # which is a method using the itemwise shipping calculator.
  def set_default_shipping_method
    self.shipping_method = Spree::ShippingMethod.where("display_on != 'back_end'").first
    if self.shipping_method
      self.save!
      self.create_shipment!
    else
      raise 'No default shipping method found'
    end
  end

  def shipping_address_from_distributor
    if distributor
      self.ship_address = distributor.pickup_address.clone

      if bill_address
        self.ship_address.firstname = bill_address.firstname
        self.ship_address.lastname = bill_address.lastname
        self.ship_address.phone = bill_address.phone
      end
    end
  end
end
