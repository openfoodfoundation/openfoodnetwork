Spree::Order.class_eval do
  belongs_to :distributor, :class_name => 'Enterprise'

  before_validation :shipping_address_from_distributor
  validate :change_distributor_validation, :if => :distributor_id_changed?
  attr_accessible :distributor_id

  after_create :set_default_shipping_method

  def change_distributor_validation
    # Check that the line_items in the current order are available from a newly selected distributor
    errors.add(:distributor_id, "The products in your cart are not available from '" + distributor.name + "'") unless can_change_to_distributor? distributor
  end

  def can_change_to_distributor? distributor
    # Distributor may not be changed once an item has been added to the cart/order, unless all items are available from the specified distributor
    line_items.empty? || (available_distributors || []).include?(distributor)
  end

  def can_change_distributor?
    # Distributor may not be changed once an item has been added to the cart/order
    line_items.empty?
  end

  def available_distributors
    # Find all other enterprises which offer all product variants contained within the current order
    distributors_with_all_variants = get_distributors_with_all_variants(Enterprise.all)
  end

  def get_distributors_with_all_variants(enterprises)
    variants_in_current_order = line_items.map{ |li| li.variant }
    distributors_with_all_variants = []
    enterprises.each do |e|
      variants_available_from_enterprise = ProductDistribution.find_all_by_distributor_id( e.id ).map{ |pd| pd.product.variants }.flatten
      distributors_with_all_variants << e if ( variants_in_current_order - variants_available_from_enterprise ).empty?
    end
    distributors_with_all_variants
  end

  def distributor=(distributor)
    raise "You cannot change the distributor of an order with products" unless distributor == self.distributor || can_change_to_distributor?(distributor)
    super(distributor)
  end

  def set_distributor!(distributor)
    self.distributor = distributor
    save!
  end

  def can_add_product_to_cart?(product)
    # Products may be added if no line items are currently in the cart or if the product is available from the current distributor
    line_items.empty? || product.distributors.include?(distributor)
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
      self.ship_address = distributor.address.clone

      if bill_address
        self.ship_address.firstname = bill_address.firstname
        self.ship_address.lastname = bill_address.lastname
        self.ship_address.phone = bill_address.phone
      end
    end
  end
end
