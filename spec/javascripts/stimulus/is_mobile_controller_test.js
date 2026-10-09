/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import is_mobile_controller from "controllers/is_mobile_controller";

describe("IsMobileController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("is-mobile", is_mobile_controller);
  });

  const setWidths = ({ inner, screen }) => {
    Object.defineProperty(window, "innerWidth", { value: inner, configurable: true });
    Object.defineProperty(window.screen, "width", { value: screen, configurable: true });
  };

  const connect = () => {
    document.body.innerHTML = `<div data-controller="is-mobile"></div>`;
    return new Promise((resolve) => setTimeout(resolve, 0));
  };

  const isMobile = () => document.body.classList.contains("is-mobile");

  it("adds is-mobile on a small screen", async () => {
    setWidths({ inner: 400, screen: 400 });
    await connect();
    expect(isMobile()).toBe(true);
  });

  it("does not add is-mobile on a large screen", async () => {
    setWidths({ inner: 1200, screen: 1200 });
    await connect();
    expect(isMobile()).toBe(false);
  });

  it("uses the smaller of innerWidth and screen.width (real phone: layout viewport is wide)", async () => {
    setWidths({ inner: 980, screen: 412 });
    await connect();
    expect(isMobile()).toBe(true);
  });

  it("toggles when the window is resized", async () => {
    setWidths({ inner: 1200, screen: 1200 });
    await connect();
    expect(isMobile()).toBe(false);

    setWidths({ inner: 400, screen: 400 });
    window.dispatchEvent(new Event("resize"));
    expect(isMobile()).toBe(true);
  });
});
