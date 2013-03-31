class Spree::ProductSet < ModelSet
  def initialize(attributes={})
    super(Spree::Product, Spree::Product.all,
          proc { |attrs| attrs[:product_id].blank? },
          attributes)
  end
end