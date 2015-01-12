module OpenFoodNetwork
  module ScopeVariantToHub
    def price
      VariantOverride.price_for(@hub, self) || super
    end

    def price_in(currency)
      Spree::Price.new(amount: price, currency: currency)
    end

    def count_on_hand
      VariantOverride.count_on_hand_for(@hub, self) || super
    end

    def decrement!(attribute, by=1)
      if attribute == :count_on_hand && VariantOverride.stock_overridden?(@hub, self)
        VariantOverride.decrement_stock! @hub, self, by
      else
        super
      end
    end
  end
end

Spree::Variant.class_eval do
  def scope_to_hub(hub)
    extend OpenFoodNetwork::ScopeVariantToHub
    @hub = hub
  end
end
