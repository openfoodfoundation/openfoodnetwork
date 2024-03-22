/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import flash_controller from "../../../app/webpacker/controllers/flash_controller";

describe("FlashController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("flash", flash_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="element" data-controller='flash' data-flash-auto-close-value='true'></div>
    `;

  });

  describe("autoClose", () => {
    jest.useFakeTimers();

    it("is cleared after about 5 seconds", () => {
      let element = document.getElementById("element");
      expect(element).not.toBe(null);

      jest.advanceTimersByTime(5500);

      element = document.getElementById("element");
      expect(element).toBe(null);
    });
  });
});
