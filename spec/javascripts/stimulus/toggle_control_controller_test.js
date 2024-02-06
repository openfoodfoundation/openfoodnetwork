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
  describe("#enableIfPresent", () => {
    describe("with input", () => {
      beforeEach(() => {
        document.body.innerHTML = `<div data-controller="toggle-control">
          <input id="input" value="" data-action="input->toggle-control#enableIfPresent" />
          <input id="control" data-toggle-control-target="control">
        </div>`;
      });

      it("Enables when input is filled", () => {
        input.value = "a"
        input.dispatchEvent(new Event("input"));

        expect(control.disabled).toBe(false);
      });

      it("Disables when input is emptied", () => {
        input.value = "test"
        input.dispatchEvent(new Event("input"));

        input.value = ""
        input.dispatchEvent(new Event("input"));

        expect(control.disabled).toBe(true);
      });
    });
  });
  describe("#toggleDisplay", () => {
    beforeEach(() => {
      document.body.innerHTML = `<div data-controller="toggle-control">
        <span id="button" data-action="click->toggle-control#toggleDisplay" data-toggle-show="true" />
        <div id="content" data-toggle-control-target="content" >
          content
        </div>
      </div>`;
    });

    it("toggles the content", () => {
      const button = document.getElementById("button");
      const content = document.getElementById("content");
      expect(content.style.display).toBe("");

      button.click();

      expect(content.style.display).toBe("block");
    });
  });
  describe("#toggleAdvancedSettings", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="toggle-control" data-toggle-control-selector-value="#content">
        <button id="remote-toggle" data-action="click->toggle-control#toggleAdvancedSettings"></button>
        <button id="remote-toggle-with-chevron" data-action="click->toggle-control#toggleAdvancedSettings">
        <i class="icon-chevron-down" data-toggle-control-target="chevron"></i>
        </button>
        </div>
        <div id="content">...</div>
        `;
    });

    it("clicking a toggle switches the visibility of the :data-remote-toggle-selector element", () => {
      const button = document.getElementById("remote-toggle");
      const content = document.getElementById("content");
      expect(content.style.display).toBe("");

      button.click();

      expect(content.style.display).toBe("none");

      button.click();

      expect(content.style.display).toBe("block");
    });

    it("clicking a toggle with a chevron icon switches the visibility of content and the direction of the icon", () => {
      const button = document.getElementById("remote-toggle-with-chevron");
      const chevron = button.querySelector("i");
      const content = document.getElementById("content");
      expect(content.style.display).toBe("");
      expect(chevron.className).toBe("icon-chevron-down");

      button.click();

      expect(content.style.display).toBe("none");
      expect(chevron.className).toBe("icon-chevron-up");

      button.click();

      expect(content.style.display).toBe("block");
      expect(chevron.className).toBe("icon-chevron-down");
    });
  });
});
