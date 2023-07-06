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
      document.body.innerHTML = `<div data-controller="dropdown" id="container">
        <span id="dropdown" data-action="click->dropdown#toggle">
          <span id="arrow" data-dropdown-target="arrow" data-expanded-class="expandedClass expandedCLass2" data-collapsed-class="collapsedClass" />
        </span>
        <div id="menu" data-dropdown-target="menu" >

        </div>
      </div>`;
    });

    afterEach(() => {
      document.body.innerHTML = "";
    });

    it("hide menu by default", () => {
      const menu = document.getElementById("menu");
      expect(menu.classList.contains("hidden")).toBe(true);
    });

    it("show menu when toggle and add/remove class on arrow", () => {
      const dropdown = document.getElementById("dropdown");
      const arrow = document.getElementById("arrow");
      const menu = document.getElementById("menu");
      expect(menu.classList.contains("hidden")).toBe(true);
      expect(arrow.classList.contains("expandedClass")).toBe(false);
      expect(arrow.classList.contains("expandedClass2")).toBe(false);
      expect(arrow.classList.contains("collapsedClass")).toBe(true);

      dropdown.click();

      expect(menu.classList.contains("hidden")).toBe(false);
      expect(arrow.classList.contains("expandedClass")).toBe(true);
      expect(arrow.classList.contains("expandedCLass2")).toBe(true);
      expect(arrow.classList.contains("collapsedClass")).toBe(false);
    });

    it ("hide menu when click outside", () => {
      const dropdown = document.getElementById("dropdown");
      const menu = document.getElementById("menu");
      dropdown.click();
      expect(menu.classList.contains("hidden")).toBe(false);

      document.body.click();

      expect(menu.classList.contains("hidden")).toBe(true);
    });

    it ("do not display menu when disabled", () => {
      const dropdown = document.getElementById("dropdown");
      const container = document.getElementById("container");
      const menu = document.getElementById("menu");
      container.classList.add("disabled");
      
      dropdown.click();

      expect(menu.classList.contains("hidden")).toBe(true);
    });
  });
});
