module Spree
  ProductProperty.class_eval do
    belongs_to :product, class_name: "Spree::Product", touch: true
  end
end
