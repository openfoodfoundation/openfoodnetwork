Spree::StockLocation.class_eval do
  def move(variant, quantity, originator = nil)
    variant.move(quantity, originator)
  end
end
