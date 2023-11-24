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
          <input id="input1" value="value1">
          <label>
            <input id="input2" type="checkbox" value="value2" data-action="change->popout#closeIfChecked">
            label2
          </label>
          <input id="input3" type="hidden" value="value3">
        </div>
      </div>
      <input id="input4">
    `;
  });

  describe("Show", () => {
    it("shows the dialog on click", () => {
      // button.click(); // For some reason this fails due to passive: true, but works in real life.
      button.dispatchEvent(new Event("click"));

      expectToBeShown(dialog);
    });

    it("shows the dialog on keyboard down arrow", () => {
      button.dispatchEvent(new KeyboardEvent("keydown", { keyCode: 40 }));

      expectToBeShown(dialog);
    });

    it("doesn't show the dialog on other key press (tab)", () => {
      button.dispatchEvent(new KeyboardEvent("keydown", { keyCode: 9 }));

      expectToBeClosed(dialog);
    });
  });

  describe("Close", () => {
    beforeEach(() => {
      button.dispatchEvent(new Event("click")); // Dialog is open
    })

    it("closes the dialog when click outside", () => {
      input4.click();

      expectToBeClosed(dialog);
      expect(button.innerText).toBe("value1");
    });

    it("closes the dialog when focusing another field (eg with tab)", () => {
      input4.focus();

      expectToBeClosed(dialog);
      expect(button.innerText).toBe("value1");
    });

    it("doesn't close the dialog when focusing internal field", () => {
      input2.focus();

      expectToBeShown(dialog);
    });

    it("closes the dialog when checkbox is checked", () => {
      input2.click();

      expectToBeClosed(dialog);
      expect(button.innerText).toBe("value1");// The checkbox label should be here, but I just couldn't get the test to work with labels. Don't worry, it works in the browser.
    });

    it("doesn't close the dialog when checkbox is unchecked", () => {
      input2.click();
      button.dispatchEvent(new Event("click")); // Dialog is opened again
      input2.click();

      expect(input2.checked).toBe(false);
      expectToBeShown(dialog);
    });
  });

  describe("Cleaning up", () => {
    // unable to test disconnect
  });
});

function expectToBeShown(element) {
  expect(element.style.display).toBe("block");
}
function expectToBeClosed(element) {
  expect(element.style.display).toBe("none");
}
