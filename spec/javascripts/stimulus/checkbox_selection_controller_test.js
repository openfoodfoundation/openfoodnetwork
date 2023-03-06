/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import checkbox_selection_controller from "../../../app/webpacker/controllers/checkbox_selection_controller";

describe("CheckboxSelectionController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("checkbox-selection", checkbox_selection_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="checkbox-selection">
        <input
          id="shippingCheckbox"
          type="checkbox"
          data-action="change->checkbox-selection#disableButtons"
          data-checkbox-selection-target="checkbox"
          data-group="shipping">
        <input
          id="distributorCheckbox"
          type="checkbox"
          data-action="change->checkbox-selection#disableButtons"
          data-checkbox-selection-target="checkbox"
          data-group="distributor">
        <span id="errorMessage" data-checkbox-selection-target="errorMessage">Error message</span>
        <input id="test-submit" type="submit" data-checkbox-selection-button />
      </div>
    `;
  });

  describe("#disableButtons", () => {
    describe("when shipping group is unchecked", () => {
      it("disables submit button", () => {
        const shippingCheckbox = document.getElementById("shippingCheckbox");
        const submit = document.getElementById("test-submit");

        expect(submit.disabled).toBe(false);

        shippingCheckbox.click();

        expect(shippingCheckbox.checked).toBe(true);

        shippingCheckbox.click();

        expect(shippingCheckbox.checked).toBe(false);
        expect(submit.disabled).toBe(true);
      });

      it("show the error message", () => {
        const shippingCheckbox = document.getElementById("shippingCheckbox");
        const errorMessage = document.getElementById("errorMessage");

        expect(errorMessage.style.display).toBe("none");

        shippingCheckbox.click()

        expect(shippingCheckbox.checked).toBe(true);

        shippingCheckbox.click()

        expect(shippingCheckbox.checked).toBe(false);
        expect(errorMessage.style.display).toBe("block");
        expect(errorMessage.innerHTML).toBe("Error message")
      });
    });

    describe("when distributor group is unchecked", () => {
      it("disables submit button", () => {
        const distributorCheckbox = document.getElementById("distributorCheckbox");
        const submit = document.getElementById("test-submit");

        expect(submit.disabled).toBe(false);

        distributorCheckbox.click();

        expect(distributorCheckbox.checked).toBe(true);

        distributorCheckbox.click();

        expect(distributorCheckbox.checked).toBe(false);
        expect(submit.disabled).toBe(true);
      });

      it("show the error message", () => {
        const distributorCheckbox = document.getElementById("distributorCheckbox");
        const errorMessage = document.getElementById("errorMessage");

        expect(errorMessage.style.display).toBe("none");

        distributorCheckbox.click();

        expect(distributorCheckbox.checked).toBe(true);

        distributorCheckbox.click();

        expect(distributorCheckbox.checked).toBe(false);
        expect(errorMessage.style.display).toBe("block");
        expect(errorMessage.innerHTML).toBe("Error message")
      });
    });
  });

  describe("#connect", () => {
    it("set error display style to none", () => {
      const errorMessage = document.getElementById("errorMessage");

      expect(errorMessage.style.display).toBe("none")
    });
  })

  describe("handleError", () => {
    describe("when checkbox is unchecked", () => {
      it("set error display style to block", () => {
        const errorMessage = document.getElementById("errorMessage");
        const distributorCheckbox = document.getElementById("distributorCheckbox");

        distributorCheckbox.click();

        expect(distributorCheckbox.checked).toBe(true);

        distributorCheckbox.click();

        expect(distributorCheckbox.checked).toBe(false);
        expect(errorMessage.style.display).toBe("block");
      });
    });

    describe("when checkbox is checked", () => {
      it("set error display style to block", () => {
        const shippingCheckbox = document.getElementById("shippingCheckbox");
        const errorMessage = document.getElementById("errorMessage");
        const distributorCheckbox = document.getElementById("distributorCheckbox");

        shippingCheckbox.click();
        distributorCheckbox.click();

        expect(distributorCheckbox.checked).toBe(true);
        expect(shippingCheckbox.checked).toBe(true);
        expect(errorMessage.style.display).toBe("none");
      });
    });
  });
});
