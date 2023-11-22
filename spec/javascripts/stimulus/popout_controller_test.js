/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import popout_controller from "../../../app/webpacker/controllers/popout_controller";

describe("PopoutController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("popout", popout_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="popout">
        <button id="button" data-popout-target="button">On demand</button>
        <div id="dialog" data-popout-target="dialog" style="display: none;">
          <input id="input1">
          <input id="input2">
        </div>
      </div>
    `;

    const button = document.getElementById("button");
    const input1 = document.getElementById("input1");
    const input2 = document.getElementById("input2");
  });

  describe("Show", () => {
    it("shows the dialog on click", () => {
      button.click();

      expect(dialog.style.display).toBe("block"); // visible
    });

    it("shows the dialog on keyboard down arrow", () => {
      button.dispatchEvent(new KeyboardEvent("keydown", { keyCode: 40 }));

      expect(dialog.style.display).toBe("block"); // visible
    });

    it("doesn't show the dialog on other key press (tab)", () => {
      button.dispatchEvent(new KeyboardEvent("keydown", { keyCode: 9 }));

      expect(dialog.style.display).toBe("none"); // not visible
    });
  });
});
