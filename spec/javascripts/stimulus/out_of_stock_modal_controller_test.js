/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import out_of_stock_modal_controller from "../../../app/webpacker/controllers/out_of_stock_modal_controller";

describe("OutOfStockModalController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("out-of-stock-modal", out_of_stock_modal_controller);
  });

  let originalWindowLocation = window.location;

  beforeEach(() => {
    Object.defineProperty(window, "location", {
      configurable: true,
      enumerable: true,
      value: new URL(window.location.href),
    });
  });

  afterEach(() => {
    Object.defineProperty(window, "location", {
      configurable: true,
      enumerable: true,
      value: originalWindowLocation,
    });
  });

  // We use window to dispatch the closing event so we don't need to set up another controller
  describe("#redirect", () => {
    describe("when redirect value is false", () => {
      beforeEach(() => {
        document.body.innerHTML = `
          <div data-controller="out-of-stock-modal" 
               data-action="closing@window->out-of-stock-modal#redirect" 
               data-out-of-stock-modal-redirect-value="false"
          >
          </div>
        `;
      });

      it("does not redirect", () => {
        const event = new Event("closing");
        window.dispatchEvent(event);

        expect(window.location.href).not.toBe("/shop");
      });
    });

    describe("when redirect value is true", () => {
      beforeEach(() => {
        document.body.innerHTML = `
          <div data-controller="out-of-stock-modal" 
               data-action="closing@window->out-of-stock-modal#redirect" 
               data-out-of-stock-modal-redirect-value="true"
          >
          </div>
        `;
      });

      it("redirects to /shop", () => {
        const event = new Event("closing");
        window.dispatchEvent(event);

        expect(window.location.pathname).toBe("/shop");
      });
    });
  });
});
