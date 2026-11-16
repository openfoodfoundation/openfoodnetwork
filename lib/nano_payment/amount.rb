# frozen_string_literal: true

module NanoPayment
  # Nano settles in raw, an integer: 1 XNO = 10^30 raw. Amounts are derived
  # here from the order total and the shop's price and kept as exact
  # rationals, so no amount is ever rounded through a float.
  module Amount
    RAW_DECIMALS = 30
    RAW_PER_XNO = 10**RAW_DECIMALS
    DECIMAL = /\A\d+(\.\d+)?\z/
    RAW = /\A\d{1,39}\z/

    module_function

    # Raw owed for `total` units of the shop currency at `xno_per_unit` XNO
    # for one unit. A result finer than one raw is rounded up to the next raw,
    # so the shop never receives less than its price.
    def raw_for(total, xno_per_unit)
      rate = decimal(xno_per_unit)
      raise ArgumentError, "The XNO price per unit must be above zero" unless rate.positive?

      (decimal(total) * rate * RAW_PER_XNO).ceil
    end

    # Raw for a decimal XNO amount ("0.05" -> 50000000000000000000000000000).
    def xno_to_raw(xno)
      raw = decimal(xno) * RAW_PER_XNO
      raise ArgumentError, "An XNO amount cannot be finer than one raw" unless raw.denominator == 1

      raw.to_i
    end

    # The XNO amount for an integer raw value, as an exact decimal string.
    def raw_to_xno(raw)
      whole, fraction = Integer(raw).divmod(RAW_PER_XNO)
      return whole.to_s if fraction.zero?

      "#{whole}.#{fraction.to_s.rjust(RAW_DECIMALS, '0').sub(/0+\z/, '')}"
    end

    # A node reports an amount as an integer of up to 39 digits; anything
    # else (a float, a sign, more digits) is not a raw amount.
    def raw?(value)
      value.is_a?(String) && RAW.match?(value)
    end

    # A non-negative exact Rational from a decimal string, an Integer or a
    # BigDecimal (Spree amounts are BigDecimal, whose #to_s is "0.1e0").
    def decimal(value)
      return exact(value.to_r) if value.is_a?(Integer)
      return exact(value.to_r) if defined?(BigDecimal) && value.is_a?(BigDecimal) && value.finite?

      text = value.to_s.strip
      raise ArgumentError, "Not a non-negative decimal: #{value.inspect}" unless
        DECIMAL.match?(text)

      Rational(text)
    end

    def exact(rational)
      raise ArgumentError, "Not a non-negative amount: #{rational}" if rational.negative?

      rational
    end
  end
end
