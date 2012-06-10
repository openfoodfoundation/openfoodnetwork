Spree::Product.class_eval do
  belongs_to :supplier

  attr_accessible :supplier_id
end