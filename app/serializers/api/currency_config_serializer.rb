# frozen_string_literal: true

class Api::CurrencyConfigSerializer < ActiveModel::Serializer
  attributes :currency, :display_currency, :symbol, :symbol_position, :hide_cents

  def currency
    CurrentConfig.get(:currency)
  end

  def display_currency
    CurrentConfig.get(:display_currency)
  end

  def symbol
    ::Money.new(1, CurrentConfig.get(:currency)).symbol
  end

  def symbol_position
    CurrentConfig.get(:currency_symbol_position)
  end

  def hide_cents
    CurrentConfig.get(:hide_cents)
  end
end
