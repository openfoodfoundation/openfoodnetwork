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
          <input id="input2" type="checkbox" data-action="change->popout#closeIfChecked">
        </div>
      </div>
      <input id="input3">
    `;

    const button = document.getElementById("button");
    const input1 = document.getElementById("input1");
    const input2 = document.getElementById("input2");
    const input3 = document.getElementById("input3");
  });

  describe("Show", () => {
    it("shows the dialog on click", () => {
      // button.click(); // For some reason this fails due to passive: true, but works in real life.
      button.dispatchEvent(new Event("click"));

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

  describe("Close", () => {
    beforeEach(() => {
      button.dispatchEvent(new Event("click")); // Dialog is open
    })

    it("closes the dialog when click outside", () => {
      input3.click();

      expect(dialog.style.display).toBe("none"); // not visible
    });

    it("closes the dialog when focusing another field (eg with tab)", () => {
      input3.focus();

      expect(dialog.style.display).toBe("none"); // not visible
    });

    it("doesn't close the dialog when focusing internal field", () => {
      input2.focus();

      expect(dialog.style.display).toBe("block"); // visible
    });

    it("closes the dialog when checkbox is checked", () => {
      input2.click();

      expect(dialog.style.display).toBe("none"); // not visible
    });

    it("doesn't close the dialog when checkbox is unchecked", () => {
      input2.click();
      button.dispatchEvent(new Event("click")); // Dialog is opened again
      input2.click();

      expect(input2.checked).toBe(false);
      expect(dialog.style.display).toBe("block"); // visible
    });
  });

  describe("Cleaning up", () => {
    // unable to test disconnect
  });
});
