# frozen_string_literal: false

require 'money'

module Spree
  class Money
    attr_reader :money

    delegate :cents, to: :money

    def initialize(amount, options = {})
      @money = ::Monetize.parse([amount, options[:currency] || CurrentConfig.get(:currency)].join)

      if options.key?(:symbol_position)
        options[:format] = position_to_format(options.delete(:symbol_position))
      end

      @options = defaults.merge(options)
    end

    # Return the currency symbol (on its own) for the current default currency
    def self.currency_symbol
      ::Money.new(0, CurrentConfig.get(:currency)).symbol
    end

    def to_s
      @money.format(@options)
    end

    def to_html(options = { html_wrap: true })
      "<span style='white-space: nowrap;'>#{@money.format(@options.merge(options))}</span>"
        .html_safe # rubocop:disable Rails/OutputSafety
    end

    def format(options = {})
      @money.format(@options.merge!(options))
    end

    def ==(other)
      @money == other.money
    end

    private

    def defaults
      {
        with_currency: CurrentConfig.get(:display_currency),
        no_cents: CurrentConfig.get(:hide_cents),
        decimal_mark: CurrentConfig.get(:currency_decimal_mark),
        thousands_separator: CurrentConfig.get(:currency_thousands_separator),
        format: position_to_format(CurrentConfig.get(:currency_symbol_position))
      }
    end

    def position_to_format(position)
      return if position.nil?

      case position.to_sym
      when :before
        '%u%n'
      when :after
        '%n %u'
      else
        raise 'Invalid symbol position'
      end
    end
  end
end
