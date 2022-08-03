/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import side_menu_controller from "../../../app/webpacker/controllers/side_menu_controller";

describe("SideMenuController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("side-menu", side_menu_controller);
  });

  describe("#side-menu", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="side-menu" data-action="side-menu:changeActiveComponent->enterprise-form#show">
          <a id="peek" href="#" data-action="side-menu#changeActiveTab" class="selected">Peek</a>
          <a id="ka" href="#" data-action="side-menu#changeActiveTab">Ka</a>
          <a id="boo" href="#" data-action="side-menu#changeActiveTab">Boo</a>
        </div>`
    });

    it("changes the selected tab", () => {
      const peek = document.getElementById("peek");
      const ka = document.getElementById("ka");
      const boo = document.getElementById("boo");

      expect(peek.className).toBe('selected')

      ka.click()
      expect(peek.className).toBe('')
      expect(ka.className).toBe('selected')

      ka.click()
      expect(ka.className).toBe('selected')
    });

  });
});
