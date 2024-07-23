/**
 * @jest-environment jsdom
 */

import localizeCurrency from "js/services/localize_currency";

describe("convert number to localised currency", function () {
  beforeAll(() => {
    const mockedToCurrency = jest.fn();
    mockedToCurrency.mockImplementation((amount, options) => {
      if (options.format == "%n %u") {
        return `${amount.toFixed(options.precision)}${options.unit}`;
      } else {
        return `${options.unit}${amount.toFixed(options.precision)}`;
      }
    });

    global.I18n = { toCurrency: mockedToCurrency };

    // Requires global var from page
    global.ofn_currency_config = {
      symbol: "$",
      symbol_position: "before",
      currency: "D",
      hide_cents: "false",
    };
  });
  // (jest still doesn't have aroundEach https://github.com/jestjs/jest/issues/4543 )
  afterAll(() => {
    delete global.I18n;
  });

  it("adds decimal fraction to an amount", function () {
    expect(localizeCurrency(10)).toEqual("$10.00");
  });

  it("handles an existing fraction", function () {
    expect(localizeCurrency(9.9)).toEqual("$9.90");
  });

  it("can use any currency symbol", function () {
    global.ofn_currency_config.symbol = "£";
    expect(localizeCurrency(404.04)).toEqual("£404.04");
  });

  it("can place symbols after the amount", function () {
    global.ofn_currency_config.symbol = "$";
    global.ofn_currency_config.symbol_position = "after";
    expect(localizeCurrency(333.3)).toEqual("333.30$");
  });

  it("can add a currency string", function () {
    global.ofn_currency_config.display_currency = true;
    global.ofn_currency_config.symbol_position = "before";
    expect(localizeCurrency(5)).toEqual("$5.00 D");
  });

  it("can hide cents", function () {
    global.ofn_currency_config.display_currency = false;
    global.ofn_currency_config.hide_cents = "true";
    expect(localizeCurrency(5)).toEqual("$5");
  });
});
