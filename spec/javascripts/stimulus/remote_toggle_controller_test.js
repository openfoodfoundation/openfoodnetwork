/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import remote_toggle_controller from "../../../app/webpacker/controllers/remote_toggle_controller";

describe("RemoteToggleController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("remote-toggle", remote_toggle_controller);
  });

  describe("#toggle", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="remote-toggle" data-remote-toggle-selector-value="#content">
          <button id="remote-toggle" data-action="click->remote-toggle#toggle"></button>
          <button id="remote-toggle-with-chevron" data-action="click->remote-toggle#toggle">
            <i class="icon-chevron-down" data-remote-toggle-target="chevron"></i>
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
