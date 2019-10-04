module Spree
  Price.class_eval do
    acts_as_paranoid without_default_scope: true

    # Allow prices to access associated soft-deleted variants.
    def variant
      Spree::Variant.unscoped { super }
    end

    private

    def check_price
      if currency.nil?
        self.currency = Spree::Config[:currency]
      end
    end
  end
end
