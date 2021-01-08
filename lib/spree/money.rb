# frozen_string_literal: false

require 'money'

module Spree
  class Money
    attr_reader :money

    delegate :cents, to: :money

    def initialize(amount, options = {})
      @money = ::Monetize.parse([amount, (options[:currency] || Spree::Config[:currency])].join)
      @options = {}
      @options[:with_currency] = Spree::Config[:display_currency]
      @options[:symbol_position] = Spree::Config[:currency_symbol_position].to_sym
      @options[:no_cents] = Spree::Config[:hide_cents]
      @options[:decimal_mark] = Spree::Config[:currency_decimal_mark]
      @options[:thousands_separator] = Spree::Config[:currency_thousands_separator]
      @options.merge!(options)
      # Must be a symbol because the Money gem doesn't do the conversion
      @options[:symbol_position] = @options[:symbol_position].to_sym
    end

    # Return the currency symbol (on its own) for the current default currency
    def self.currency_symbol
      ::Money.new(0, Spree::Config[:currency]).symbol
    end

    def to_s
      @money.format(@options)
    end

    def to_html(options = { html: true })
      output = @money.format(@options.merge(options))
      if options[:html]
        # 1) prevent blank, breaking spaces
        # 2) prevent escaping of HTML character entities
        output = output.sub(" ", "&nbsp;").html_safe
      end
      output
    end

    def format(options = {})
      @money.format(@options.merge!(options))
    end

    def ==(other)
      @money == other.money
    end
  end
end
