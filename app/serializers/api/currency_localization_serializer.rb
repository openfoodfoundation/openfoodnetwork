class Api::CurrencyLocalizationSerializer < ActiveModel::Serializer
  attributes :currency, :display_currency, :symbol, :symbol_position, :hide_cents, :decimal_mark, :thousands_separator

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

  def decimal_mark 
    Spree::Config[:currency_decimal_mark]
  end

  def thousands_separator 
    Spree::Config[:currency_thousands_separator]
  end

end
