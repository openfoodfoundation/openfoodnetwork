/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import dropdown_controller from "../../../app/webpacker/controllers/dropdown_controller";

describe("Dropdown controller", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("dropdown", dropdown_controller);
  });

  describe("Controller", () => {
    beforeEach(() => {
      document.body.innerHTML = `<div id="container">
        <details data-controller="dropdown" id="dropdown">
          <summary id='summary'>
            <span class="icon-reorder">
            Actions
            </span>
          </summary>
          <div id = "menu" class="menu" data-action="click->dropdown#closeOnMenu">
            <div class="menu_item">
              <span>Item 1</span>
              <span>Item 2</span>
            </div>
          </div>
        </details>
      </div>`;
    });

    afterEach(() => {
      document.body.innerHTML = "";
    });

    it("hide menu when click outside", () => {
      const dropdown = document.getElementById("dropdown");
      const menu = document.getElementById("menu");
      //open the details
      dropdown.toggleAttribute("open");
      //click elsewhere
      document.body.click();

      expect(dropdown.open).toBe(false);
    });
  });
});
