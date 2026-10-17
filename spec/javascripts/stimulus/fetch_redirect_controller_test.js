/**
 * @jest-environment jsdom
 * @jest-environment-options {"url": "http://www.example.com/admin/order_cycles"}
 */

import { Application } from "stimulus";
import { navigateToLocation, reloadLocation } from "js/window_location_wrapper";
import showHttpError from "js/services/show_http_error";
import fetch_redirect_controller from "../../../app/webpacker/controllers/fetch_redirect_controller";

jest.mock("js/window_location_wrapper");
jest.mock("js/services/show_http_error");

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("FetchRedirectController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("fetch-redirect", fetch_redirect_controller);
  });

  beforeEach(async () => {
    global.fetch = jest.fn();
    window.confirm = jest.fn(() => true);

    document.body.innerHTML = `
      <meta name="csrf-token" content="test-csrf-token">
      <a
        data-controller="fetch-redirect"
        data-fetch-redirect-method-value="delete"
        data-fetch-redirect-confirm-message-value="Are you sure?"
        data-action="click->fetch-redirect#request"
        href="/admin/order_cycles/42"
      ></a>
    `;

    await flush();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it("requests the URL and reloads the page on a redirect", async () => {
    global.fetch = jest.fn(() => Promise.resolve({ type: "opaqueredirect" }));

    document.querySelector("a").click();
    await flush();

    expect(global.fetch).toHaveBeenCalledTimes(1);
    const [url, options] = global.fetch.mock.calls[0];
    expect(url).toContain("/admin/order_cycles/42");
    expect(options.method).toEqual("delete");
    expect(options.headers["X-CSRF-Token"]).toEqual("test-csrf-token");
    expect(options.redirect).toEqual("manual");
    expect(reloadLocation).toHaveBeenCalled();
    expect(navigateToLocation).not.toHaveBeenCalled();
  });

  it("navigates to the redirect target when one is set", async () => {
    global.fetch = jest.fn(() => Promise.resolve({ type: "opaqueredirect" }));

    document.querySelector("a").dataset.fetchRedirectRedirectToValue = "/admin/order_cycles";
    document.querySelector("a").click();
    await flush();

    expect(navigateToLocation).toHaveBeenCalledWith("/admin/order_cycles");
    expect(reloadLocation).not.toHaveBeenCalled();
  });

  it("does not request when the confirmation is declined", async () => {
    window.confirm = jest.fn(() => false);

    document.querySelector("a").click();
    await flush();

    expect(global.fetch).not.toHaveBeenCalled();
    expect(reloadLocation).not.toHaveBeenCalled();
  });

  it("shows an error when the response is not a redirect", async () => {
    global.fetch = jest.fn(() => Promise.resolve({ type: "basic", status: 500 }));

    document.querySelector("a").click();
    await flush();

    expect(showHttpError).toHaveBeenCalledWith(500);
    expect(reloadLocation).not.toHaveBeenCalled();
  });
});
