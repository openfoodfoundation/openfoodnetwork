/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import toggle_controller from "../../../app/webpacker/controllers/toggle_control_controller";

describe("ToggleControlController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("toggle-control", toggle_controller);
  });

  describe("#disableIfPresent", () => {
    describe("with checkbox", () => {
      beforeEach(() => {
        document.body.innerHTML = `<div data-controller="toggle-control">
          <input id="checkbox" type="checkbox" value="1" data-action="change->toggle-control#disableIfPresent" />
          <input id="control" data-toggle-control-target="control">
        </div>`;
      });

      it("Disables when checkbox is checked", () => {
        checkbox.click();
        expect(checkbox.checked).toBe(true);

        expect(control.disabled).toBe(true);
      });

      it("Enables when checkbox is un-checked", () => {
        checkbox.click();
        checkbox.click();
        expect(checkbox.checked).toBe(false);

        expect(control.disabled).toBe(false);
      });
    });
    describe("with input", () => {
      beforeEach(() => {
        document.body.innerHTML = `<div data-controller="toggle-control">
          <input id="input" value="" data-action="input->toggle-control#disableIfPresent" />
          <input id="control" data-toggle-control-target="control">
        </div>`;
      });

      it("Disables when input is filled", () => {
        input.value = "test"
        input.dispatchEvent(new Event("input"));

        expect(control.disabled).toBe(true);
      });

      it("Enables when input is emptied", () => {
        input.value = "test"
        input.dispatchEvent(new Event("input"));

        input.value = ""
        input.dispatchEvent(new Event("input"));

        expect(control.disabled).toBe(false);
      });
    });
  });
});
