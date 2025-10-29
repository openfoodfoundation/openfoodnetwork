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

  describe("Show", () => {
    beforeEach(() => {
      document.body.innerHTML = htmlTemplate();
    });

    it("shows the dialog on click", () => {
      // button.click(); // For some reason this fails due to passive: true, but works in real life.
      button.dispatchEvent(new Event("click"));

      expectToBeShown(dialog);
    });

    it("shows the dialog on keyboard down arrow", () => {
      button.dispatchEvent(new KeyboardEvent("keydown", { keyCode: 40 }));

      expectToBeShown(dialog);
    });

    it("shows and updates on number press", () => {
      button.dispatchEvent(new KeyboardEvent("keydown", { key: "1" }));

      expectToBeShown(dialog);
      expect(input1.value).toBe("1");
    });

    it("shows and updates on character press", () => {
      button.dispatchEvent(new KeyboardEvent("keydown", { key: "a" }));

      expectToBeShown(dialog);
      expect(input1.value).toBe("a");
    });

    it("doesn't show the dialog on control key press (tab)", () => {
      button.dispatchEvent(new KeyboardEvent("keydown", { keyCode: 9 }));

      expectToBeClosed(dialog);
    });
  });

  describe("Close", () => {
    beforeEach(() => {
      document.body.innerHTML = htmlTemplate();
    });
    // For some reason this has to be in a separate block
    beforeEach(() => {
      button.dispatchEvent(new Event("click")); // Dialog is open
    });

    it("closes the dialog when click outside", () => {
      input4.click();

      expectToBeClosed(dialog);
      expect(button.textContent).toBe("value1");
    });

    it("closes the dialog when focusing another field (eg with tab)", () => {
      input4.focus();

      expectToBeClosed(dialog);
      expect(button.textContent).toBe("value1");
    });

    it("doesn't close the dialog when focusing internal field", () => {
      input2.focus();

      expectToBeShown(dialog);
    });

    it("closes the dialog when checkbox is checked", () => {
      input2.click();

      expectToBeClosed(dialog);
      // and includes the checkbox label
      expect(button.textContent).toBe("value1,label2");
    });

    it("doesn't close the dialog when checkbox is unchecked", () => {
      input2.click();
      button.dispatchEvent(new Event("click")); // Dialog is opened again
      input2.click();

      expect(input2.checked).toBe(false);
      expectToBeShown(dialog);
    });

    it("doesn't close the dialog when a field is invalid", () => {
      input1.value = ""; // field is required

      input4.click();
      expectToBeShown(dialog);
      // Browser will show a validation message
    });

    it("only shows enabled fields in display summary", () => {
      input1.disabled = true;
      input2.click(); // checkbox selected

      expectToBeClosed(dialog);
      expect(button.textContent).toBe("label2");
    });
  });

  describe("disable update-display", () => {
    beforeEach(() => {
      document.body.innerHTML = htmlTemplate({ updateDisplay: "false" });
    });

    it("doesn't update display value", () => {
      expect(button.textContent).toBe("On demand");
      button.dispatchEvent(new Event("click")); // Dialog is open
      input4.click(); //close dialog

      expectToBeClosed(dialog);
      expect(button.textContent).toBe("On demand");
    });
  });

  describe("Cleaning up", () => {
    // unable to test disconnect
  });
});

function htmlTemplate(opts = { updateDisplay: "" }) {
  return `
    <div data-controller="popout" data-popout-update-display-value="${opts["updateDisplay"]}">
      <button id="button" data-popout-target="button">On demand</button>
      <div id="dialog" data-popout-target="dialog" style="display: none;">
        <input id="input1" value="value1" required>
        <label>
          <input id="input2" type="checkbox" value="value2" data-action="change->popout#closeIfChecked">
          label2
        </label>
        <input id="input3" type="hidden" value="value3">
      </div>
    </div>
    <input id="input4">
  `;
}

function expectToBeShown(element) {
  expect(element.style.display).toBe("block");
}
function expectToBeClosed(element) {
  expect(element.style.display).toBe("none");
}
