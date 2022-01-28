/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import toggle_controller from "../../../app/webpacker/controllers/toggle_controller";

describe("ToggleController", () => {
  describe("#toggle", () => {
    beforeEach(() => {
      document.body.innerHTML = `<div data-controller="toggle">
        <button id="toggle" data-action="click->toggle#toggle"></button>
        <button id="toggle-show" data-action="click->toggle#toggle" data-toggle-show="true"></button>
        <button id="toggle-hide" data-action="click->toggle#toggle" data-toggle-show="false"></button>
        <button id="toggle-with-chevron" data-action="click->toggle#toggle">
          <i class="icon-chevron-down"></i>
        </button>
        <div id="visible-content" data-toggle-target="content" style="display: block;">
          visible content
        </div>
        <div id="invisible-content" data-toggle-target="content" style="display: none;">
          invisible content
        </div>
      </div>`;

      const application = Application.start();
      application.register("toggle", toggle_controller);
    });

    it("toggling a button which shows and hides content switches the visibility of content", () => {
      const button = document.getElementById("toggle");
      const invisibleContent = document.getElementById("invisible-content");
      const visibleContent = document.getElementById("visible-content");
      expect(invisibleContent.style.display).toBe("none");
      expect(visibleContent.style.display).toBe("block");

      button.click();

      expect(invisibleContent.style.display).toBe("block");
      expect(visibleContent.style.display).toBe("none");
    });

    it("toggling a button with 'data-toggle-show=true' shows invisible content", () => {
      const button = document.getElementById("toggle-show");
      const invisibleContent = document.getElementById("invisible-content");
      expect(invisibleContent.style.display).toBe("none");

      button.click();

      expect(invisibleContent.style.display).toBe("block");
    });

    it("toggling a button with 'data-toggle-show=true' doesn't hide visible content", () => {
      const button = document.getElementById("toggle-show");
      const visibleContent = document.getElementById("visible-content");
      expect(visibleContent.style.display).toBe("block");

      button.click();

      expect(visibleContent.style.display).toBe("block");
    });

    it("toggling a button with 'data-toggle-show=false' hides visible content", () => {
      const button = document.getElementById("toggle-hide");
      const visibleContent = document.getElementById("visible-content");
      expect(visibleContent.style.display).toBe("block");

      button.click();

      expect(visibleContent.style.display).toBe("none");
    });

    it("toggling a button with 'data-toggle-show=false' doesn't show invisible content", () => {
      const button = document.getElementById("toggle-hide");
      const invisibleContent = document.getElementById("invisible-content");
      expect(invisibleContent.style.display).toBe("none");

      button.click();

      expect(invisibleContent.style.display).toBe("none");
    });

    it("toggling a button with a chevron icon switches the visibility of content and the direction of the icon", () => {
      const buttonA = document.getElementById("toggle-with-chevron");
      const chevron = buttonA.querySelector("i");
      const invisibleContent = document.getElementById("invisible-content");
      const visibleContent = document.getElementById("visible-content");
      expect(invisibleContent.style.display).toBe("none");
      expect(visibleContent.style.display).toBe("block");
      expect(chevron.className).toBe("icon-chevron-down");

      buttonA.click();

      expect(invisibleContent.style.display).toBe("block");
      expect(visibleContent.style.display).toBe("none");
      expect(chevron.className).toBe("icon-chevron-up");
    });
  });
});
