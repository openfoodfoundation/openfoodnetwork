/**
 * @jest-environment jsdom
 */

import showHttpError from "js/services/show_http_error";

describe("showHttpError service", function () {
  beforeEach(() => {
    global.alert = jest.fn();
    global.I18n = {
      t: jest.fn((key) => key),
    };
  });

  afterEach(() => {
    delete global.alert;
    delete global.I18n;
  });

  it("ignores missing errors", function () {
    showHttpError(undefined);
    expect(global.alert).not.toHaveBeenCalled();
  });

  it("ignores aborted fetch requests", function () {
    showHttpError({ name: "AbortError" });
    expect(global.alert).not.toHaveBeenCalled();
  });

  it("alerts on network errors", function () {
    showHttpError(new TypeError("Failed to fetch"));
    expect(global.I18n.t).toHaveBeenCalledWith("errors.network_error.message");
    expect(global.alert).toHaveBeenCalledWith("errors.network_error.message");
  });

  it("alerts on unauthorized responses", function () {
    showHttpError({ statusCode: 401 });
    expect(global.I18n.t).toHaveBeenCalledWith("errors.unauthorized.message");
    expect(global.alert).toHaveBeenCalledWith("errors.unauthorized.message");
  });

  it("alerts on server errors", function () {
    showHttpError({ statusCode: 500 });
    expect(global.I18n.t).toHaveBeenCalledWith("errors.general_error.message");
    expect(global.alert).toHaveBeenCalledWith("errors.general_error.message");
  });
});
