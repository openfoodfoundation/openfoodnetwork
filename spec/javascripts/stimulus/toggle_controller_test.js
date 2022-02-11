/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import toggle_controller from "../../../app/webpacker/controllers/toggle_controller";

describe("ToggleController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("toggle", toggle_controller);
  });

  describe("#toggle", () => {
    beforeEach(() => {
      document.body.innerHTML = `<div data-controller="toggle">
        <span id="button" data-action="click->toggle#toggle" data-toggle-show="true" />
        <div id="content" data-toggle-target="content" >
          content
        </div>
      </div>`;
    });

    it("toggle the content", () => {
      const button = document.getElementById("button");
      const content = document.getElementById("content");
      expect(content.style.display).toBe("");

      button.click();

      expect(content.style.display).toBe("block");
    });
  });
});
