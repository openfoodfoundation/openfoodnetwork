/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import checkbox_display_controller from "../../../app/webpacker/controllers/checkbox_display_controller";

describe("CheckboxDisplayController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("checkbox-display", checkbox_display_controller);
  });

  describe("#toggle", () => {
    beforeEach(() => {
      document.body.innerHTML = `<div >
        <input type="checkbox" id="checkbox" data-controller="checkbox-display" data-checkbox-display-target-id-value="content" />
        <div id="content">
          content
        </div>
      </div>`;
    });

    it("show the content if the checkbox is checked, hide content either", () => {
      const checkbox = document.getElementById("checkbox");
      const content = document.getElementById("content");
      
      expect(content.style.display).toBe("none");

      checkbox.click();

      expect(content.style.display).toBe("block");

      checkbox.click();

      expect(content.style.display).toBe("none");
    });
  });
});
