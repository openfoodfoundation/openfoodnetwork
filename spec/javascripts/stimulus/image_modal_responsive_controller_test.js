/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import image_modal_responsive_controller from "controllers/image_modal_responsive_controller";

describe("ImageModalResponsiveController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("image-modal-responsive", image_modal_responsive_controller);
  });

  const setWidths = ({ inner, screen }) => {
    Object.defineProperty(window, "innerWidth", { value: inner, configurable: true });
    Object.defineProperty(window.screen, "width", { value: screen, configurable: true });
  };

  const connect = () => {
    document.body.innerHTML = `
      <div data-controller="image-modal-responsive">
        <div class="reveal-modal modal-component image-upload-modal"></div>
      </div>`;
    return new Promise((resolve) => setTimeout(resolve, 0));
  };

  const modal = () => document.querySelector(".image-upload-modal");

  it("adds is-mobile on a small screen", async () => {
    setWidths({ inner: 400, screen: 400 });
    await connect();
    expect(modal().classList.contains("is-mobile")).toBe(true);
  });

  it("does not add is-mobile on a large screen", async () => {
    setWidths({ inner: 1200, screen: 1200 });
    await connect();
    expect(modal().classList.contains("is-mobile")).toBe(false);
  });

  it("uses the smaller of innerWidth and screen.width (real phone: layout viewport is wide)", async () => {
    setWidths({ inner: 980, screen: 412 });
    await connect();
    expect(modal().classList.contains("is-mobile")).toBe(true);
  });

  it("toggles when the window is resized", async () => {
    setWidths({ inner: 1200, screen: 1200 });
    await connect();
    expect(modal().classList.contains("is-mobile")).toBe(false);

    setWidths({ inner: 400, screen: 400 });
    window.dispatchEvent(new Event("resize"));
    expect(modal().classList.contains("is-mobile")).toBe(true);
  });
});
