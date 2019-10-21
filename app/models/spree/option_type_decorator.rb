module Spree
  OptionType.class_eval do
    has_many :products, through: :product_option_types
  end
end
