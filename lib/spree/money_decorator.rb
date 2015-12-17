Spree::Money.class_eval do

  # return the currency symbol (on its own) for the current default currency
  def self.currency_symbol
    Money.new(0, Spree::Config[:currency]).symbol
  end

  def rounded
    @options[:no_cents] = true if @money.amount % 1 == 0
    to_s
  end
end
