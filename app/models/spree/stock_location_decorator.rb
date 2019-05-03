Spree::StockLocation.class_eval do
  def move(variant, quantity, originator = nil)
    variant.move(quantity, originator)
  end

  def fill_status(variant, quantity)
    variant.fill_status(quantity)
  end
end
