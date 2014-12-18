Spree::Money.class_eval do

  # return the currency symbol (on it's own) for the current default currency 
  def self.currency_symbol
    Money.new(0, Spree::Config[:currency]).symbol
  end
end
