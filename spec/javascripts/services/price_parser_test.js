/**
 * @jest-environment jsdom
 */

import PriceParse from "js/services/price_parser";

describe("PriceParser service", function () {
  let priceParser = null;

  beforeEach(() => {
    priceParser = new PriceParse();
  });

  describe("test internal method with Regexp", function () {
    describe("test replaceCommaByFinalPoint() method", function () {
      it("handle the default case (with two numbers after comma)", function () {
        expect(priceParser.replaceCommaByFinalPoint("1,00")).toEqual("1.00");
      });
      it("doesn't confuse with thousands separator", function () {
        expect(priceParser.replaceCommaByFinalPoint("1,000")).toEqual("1,000");
      });
      it("handle also when there is only one number after the decimal separator", function () {
        expect(priceParser.replaceCommaByFinalPoint("1,0")).toEqual("1.0");
      });
    });

    describe("test removeThousandsSeparator() method", function () {
      it("handle the default case", function () {
        expect(priceParser.removeThousandsSeparator("1,000", ",")).toEqual("1000");
        expect(priceParser.removeThousandsSeparator("1,000,000", ",")).toEqual("1000000");
      });
      it("handle the case with decimal separator", function () {
        expect(priceParser.removeThousandsSeparator("1,000,000.00", ",")).toEqual("1000000.00");
      });
      it("handle the case when it is actually a decimal separator (and not a thousands one)", function () {
        expect(priceParser.removeThousandsSeparator("1,00", ",")).toEqual("1,00");
      });
    });
  });

  describe("with point as decimal separator and comma as thousands separator for I18n service", function () {
    beforeAll(() => {
      const mockedToCurrency = jest.fn();
      mockedToCurrency.mockImplementation((arg) => {
        if (arg == 0.1) {
          return "0.1";
        } else if (arg == 1000) {
          return "1,000";
        }
      });

      global.I18n = { toCurrency: mockedToCurrency };
    });
    // (jest still doesn't have aroundEach https://github.com/jestjs/jest/issues/4543 )
    afterAll(() => {
      delete global.I18n;
    });

    it("handle point as decimal separator", function () {
      expect(priceParser.parse("1.00")).toEqual(1.0);
    });

    it("handle point as decimal separator", function () {
      expect(priceParser.parse("1.000")).toEqual(1.0);
    });

    it("also handle comma as decimal separator", function () {
      expect(priceParser.parse("1,0")).toEqual(1.0);
    });

    it("also handle comma as decimal separator", function () {
      expect(priceParser.parse("1,00")).toEqual(1.0);
    });

    it("also handle comma as decimal separator", function () {
      expect(priceParser.parse("11,00")).toEqual(11.0);
    });

    it("handle comma as decimal separator but not confusing with thousands separator", function () {
      expect(priceParser.parse("11,000")).toEqual(11000);
    });

    it("handle point as decimal separator and comma as thousands separator", function () {
      expect(priceParser.parse("1,000,000.00")).toEqual(1000000);
    });

    it("handle integer number", function () {
      expect(priceParser.parse("10")).toEqual(10);
    });

    it("handle integer number with comma as thousands separator", function () {
      expect(priceParser.parse("1,000")).toEqual(1000);
    });

    it("handle integer number with no thousands separator", function () {
      expect(priceParser.parse("1000")).toEqual(1000);
    });
  });

  describe("with comma as decimal separator and final point as thousands separator for I18n service", function () {
    beforeAll(() => {
      const mockedToCurrency = jest.fn();
      mockedToCurrency.mockImplementation((arg) => {
        if (arg == 0.1) {
          return "0,1";
        } else if (arg == 1000) {
          return "1.000";
        }
      });

      global.I18n = { toCurrency: mockedToCurrency };
    });
    // (jest still doesn't have aroundEach https://github.com/jestjs/jest/issues/4543 )
    afterAll(() => {
      delete global.I18n;
    });

    it("handle comma as decimal separator", function () {
      expect(priceParser.parse("1,00")).toEqual(1.0);
    });

    it("handle comma as decimal separator with one digit after the comma", function () {
      expect(priceParser.parse("11,0")).toEqual(11.0);
    });

    it("handle comma as decimal separator with two digit after the comma", function () {
      expect(priceParser.parse("11,00")).toEqual(11.0);
    });

    it("handle comma as decimal separator with three digit after the comma", function () {
      expect(priceParser.parse("11,000")).toEqual(11.0);
    });

    it("also handle point as decimal separator", function () {
      expect(priceParser.parse("1.00")).toEqual(1.0);
    });

    it("also handle point as decimal separator with integer part with two digits", function () {
      expect(priceParser.parse("11.00")).toEqual(11.0);
    });

    it("handle point as decimal separator and final point as thousands separator", function () {
      expect(priceParser.parse("1.000.000,00")).toEqual(1000000);
    });

    it("handle integer number", function () {
      expect(priceParser.parse("10")).toEqual(10);
    });
  });
});
