# frozen_string_literal: true

class Api::CurrencyConfigSerializer < ActiveModel::Serializer
  attributes :currency, :display_currency, :symbol, :symbol_position, :hide_cents

  def currency
    Spree::Config[:currency]
  end

  def display_currency
    Spree::Config[:display_currency]
  end

  def symbol
    ::Money.new(1, Spree::Config[:currency]).symbol
  end

  def symbol_position
    Spree::Config[:currency_symbol_position]
  end

  def hide_cents
    Spree::Config[:hide_cents]
  end
end
