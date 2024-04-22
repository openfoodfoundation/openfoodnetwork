# frozen_string_literal: true

# Wraps repeatedly-called configs in a CurrentAttributes object so they only get fetched once
# per request at most, eg: CurrentConfig.get(:available_units) for Spree::Config[:available_units]

class CurrentConfig < ActiveSupport::CurrentAttributes
  attribute :display_currency, :hide_cents, :currency_decimal_mark,
            :currency_thousands_separator, :currency_symbol_position, :available_units

  def get(config_key)
    return public_send(config_key) unless public_send(config_key).nil?

    public_send("#{config_key}=", Spree::Config.public_send(config_key))
  end

  def currency
    ENV.fetch("CURRENCY")
  end
end
