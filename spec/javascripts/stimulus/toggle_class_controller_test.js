/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import toggle_class_controller from "../../../app/webpacker/controllers/toggle_class_controller";

describe("ToggleClassController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("toggle-class", toggle_class_controller);
  });

  describe("toggle-class", () => {
    beforeEach(() => {
      document.body.innerHTML = `<div id="parent" data-controller="toggle-class" data-toggle-class-target="mark">
          <p id="child" data-action="mouseenter->toggle-class#addClass click->toggle-class#removeClass" data-toggle-class-class-list-param='["make", "cooler"]' >Change my parent!</p>
        </div>`;
    });

    it("adds the class to the mark", () => {
      const mark = document.getElementById("parent");
      const classChanger = document.getElementById("child");
      expect(mark.className).toBe("")

      classChanger.dispatchEvent(new Event("mouseenter"));
      expect(mark.className).toBe("make cooler");
    });

    it("removes the class from the mark", () => {
      const mark = document.getElementById("parent");
      const classChanger = document.getElementById("child");

      classChanger.dispatchEvent(new Event("mouseenter"));
      expect(mark.className).toBe("make cooler");

      classChanger.click()
      expect(mark.className).toBe("")
    });
  });
});
