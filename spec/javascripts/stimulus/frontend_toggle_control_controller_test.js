/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import frontendToggleController from "controllers/frontend_toggle_control_controller";

describe("FrontendToggleControlController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("frontend-toggle-control", frontendToggleController);
  });

  describe("#toggleDispay", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="frontend-toggle-control" data-frontend-toggle-control-selector-value="#content">
          <div id="class-update" class="closed" data-frontend-toggle-control-target="classUpdate">
            <button id="remote-toggle" data-action="click->frontend-toggle-control#toggleDisplay"></button>
            <i class="ofn-i_005-caret-down" data-frontend-toggle-control-target="chevron"></i>
          </div>
        </div>
        <div id="content">...</div>
        `;
    });

    it("switches the visibility of the element macthing the selector value", () => {
      const button = document.getElementById("remote-toggle");
      const content = document.getElementById("content");
      expect(content.style.display).toBe("");

      button.click();

      expect(content.style.display).toBe("none");

      button.click();

      expect(content.style.display).toBe("block");
    });

    it("switches the direction of the chevron icon", () => {
      const button = document.getElementById("remote-toggle");
      const chevron = document.querySelector("i");

      expect(chevron.className).toBe("ofn-i_005-caret-down");

      button.click();

      expect(chevron.className).toBe("ofn-i_006-caret-up");

      button.click();

      expect(chevron.className).toBe("ofn-i_005-caret-down");
    });

    it("toggles the open/closed class on the matching targets", () => {
      const button = document.getElementById("remote-toggle");
      const div = document.getElementById("class-update");

      expect(div.className).toBe("closed");

      button.click();

      expect(div.className).toBe("open");

      button.click();

      expect(div.className).toBe("closed");
    });
  });
});
