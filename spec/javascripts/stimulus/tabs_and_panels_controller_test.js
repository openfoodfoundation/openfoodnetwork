/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import tabs_and_panels_controller from "../../../app/webpacker/controllers/tabs_and_panels_controller";

describe("EnterprisePanelController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("tabs-and-panels", tabs_and_panels_controller);
  });

  describe("#tabs-and-panels", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="tabs-and-panels" data-tabs-and-panels-class-name-value="selected">
          <a id="peek" href="#" data-action="tabs-and-panels#changeActivePanel tabs-and-panels#changeActiveTab" class="selected" data-tabs-and-panels-target="tab">Peek</a>
          <a id="ka" href="#" data-action="tabs-and-panels#changeActivePanel tabs-and-panels#changeActiveTab" data-tabs-and-panels-target="tab">Ka</a>
          <a id="boo" href="#" data-action="tabs-and-panels#changeActivePanel tabs-and-panels#changeActiveTab" data-tabs-and-panels-target="tab">Boo</a>


          <div id="peek_panel" data-tabs-and-panels-target="panel default">Peek me</div>
          <div id="ka_panel" data-tabs-and-panels-target="panel">Ka you</div>
          <div id="boo_panel" data-tabs-and-panels-target="panel">Boo three</div>
        </div>`;
    });

    it("displays only the default panel", () => {
      const peekPanel = document.getElementById("peek_panel");
      const kaPanel = document.getElementById("ka_panel");
      const booPanel = document.getElementById("boo_panel");

      expect(peekPanel.style.display).toBe("block");
      expect(kaPanel.style.display).toBe("none");
      expect(booPanel.style.display).toBe("none");
    });

    it("displays appropriate panel when associated tab is clicked", () => {
      const kaPanel = document.getElementById("ka_panel");
      const ka = document.getElementById("ka");

      expect(kaPanel.style.display).toBe("none");
      ka.click();
      expect(kaPanel.style.display).toBe("block");
    });
  });
});
