# frozen_string_literal: false

require 'spec_helper'

describe Spree::Money do
  include PreferencesHelper

  before do
    configure_spree_preferences do |config|
      config.currency = "USD"
      config.currency_symbol_position = :before
      config.display_currency = false
    end
  end

  it "formats correctly" do
    money = Spree::Money.new(10)
    expect(money.to_s).to eq("$10.00")
  end

  it "can get cents" do
    money = Spree::Money.new(10)
    expect(money.cents).to eq(1000)
  end

  context "with currency" do
    it "passed in option" do
      money = Spree::Money.new(10, with_currency: true, html_wrap: false)
      expect(money.to_s).to eq("$10.00 USD")
    end

    it "config option" do
      Spree::Config[:display_currency] = true
      money = Spree::Money.new(10, html_wrap: false)
      expect(money.to_s).to eq("$10.00 USD")
    end
  end

  context "hide cents" do
    it "hides cents suffix" do
      Spree::Config[:hide_cents] = true
      money = Spree::Money.new(10)
      expect(money.to_s).to eq("$10")
    end

    it "shows cents suffix" do
      Spree::Config[:hide_cents] = false
      money = Spree::Money.new(10)
      expect(money.to_s).to eq("$10.00")
    end
  end

  context "currency parameter" do
    context "when currency is specified in Canadian Dollars" do
      it "uses the currency param over the global configuration" do
        money = Spree::Money.new(10, currency: 'CAD', with_currency: true, html_wrap: false)
        expect(money.to_s).to eq("$10.00 CAD")
      end
    end

    context "when currency is specified in Japanese Yen" do
      it "uses the currency param over the global configuration" do
        money = Spree::Money.new(100, currency: 'JPY', html_wrap: false)
        expect(money.to_s).to eq("¥100")
      end
    end
  end

  context "symbol positioning" do
    it "passed in option" do
      money = Spree::Money.new(10, symbol_position: :after, html_wrap: false)
      expect(money.to_s).to eq("10.00 $")
    end

    it "passed in option string" do
      money = Spree::Money.new(10, symbol_position: "after", html_wrap: false)
      expect(money.to_s).to eq("10.00 $")
    end

    it "config option" do
      Spree::Config[:currency_symbol_position] = :after
      money = Spree::Money.new(10, html_wrap: false)
      expect(money.to_s).to eq("10.00 $")
    end

    it 'raises with invalid position' do
      expect { Spree::Money.new(10, symbol_position: 'invalid') }
        .to raise_error('Invalid symbol position')
    end
  end

  context "EUR" do
    before do
      configure_spree_preferences do |config|
        config.currency = "EUR"
        config.currency_symbol_position = :after
        config.display_currency = false
      end
    end

    # Regression test for Spree #2634
    it "formats as plain by default" do
      money = Spree::Money.new(10)
      expect(money.to_s).to eq("10.00 €")
    end

    # Regression test for Spree #2632
    it "acknowledges decimal mark option" do
      Spree::Config[:currency_decimal_mark] = ","
      money = Spree::Money.new(10)
      expect(money.to_s).to eq("10,00 €")
    end

    # Regression test for Spree #2632
    it "acknowledges thousands separator option" do
      Spree::Config[:currency_thousands_separator] = "."
      money = Spree::Money.new(1000)
      expect(money.to_s).to eq("1.000.00 €")
    end

    # rubocop:disable Layout/LineLength
    it "formats as HTML if asked (nicely) to" do
      money = Spree::Money.new(10)
      # The HTMLified version of the euro sign
      expect(money.to_html).to eq(
        "<span style='white-space: nowrap;'><span class=\"money-whole\">10</span><span class=\"money-decimal-mark\">.</span><span class=\"money-decimal\">00</span> <span class=\"money-currency-symbol\">&#x20AC;</span></span>"
      )
    end
    # rubocop:enable Layout/LineLength
  end
end
