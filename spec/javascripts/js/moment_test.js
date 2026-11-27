/**
 * @jest-environment jsdom
 */

describe("moment setup", () => {
  afterEach(() => {
    document.documentElement.removeAttribute("lang");
    jest.resetModules();
  });

  const loadMoment = () => {
    jest.isolateModules(() => require("js/moment"));
    return window.moment;
  };

  it("uses the page language", () => {
    document.documentElement.lang = "pt-BR";

    expect(loadMoment().locale()).toBe("pt-br");
  });

  it("falls back to English for unknown languages", () => {
    document.documentElement.lang = "xx-YY";

    expect(loadMoment().locale()).toBe("en");
  });

  it("defaults to English without a page language", () => {
    expect(loadMoment().locale()).toBe("en");
  });
});
