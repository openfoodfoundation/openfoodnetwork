/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import side_menu_controller from "../../../app/webpacker/controllers/side_menu_controller";
import enterprise_form_controller from "../../../app/webpacker/controllers/enterprise_form_controller";

describe("EnterpriseFormController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("side-menu", side_menu_controller);
    application.register("enterprise-form", enterprise_form_controller);
  });

  describe("#side-menu", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="side-menu enterprise-form" data-action="side-menu:changeActiveComponent->enterprise-form#show">
          <a id="peek" href="#" data-action="side-menu#changeActiveTab" class="selected">Peek</a>
          <a id="ka" href="#" data-action="side-menu#changeActiveTab">Ka</a>
          <a id="boo" href="#" data-action="side-menu#changeActiveTab">Boo</a>

          <div id="peek_form" data-enterprise-form-target="form default">Peek me</div>
          <div id="ka_form" data-enterprise-form-target="form">Ka you</div>
          <div id="boo_form" data-enterprise-form-target="form">Boo three</div>
        </div>`
    });

    it("displays only the default content", () => {
      const peekForm = document.getElementById("peek_form");
      const kaForm = document.getElementById("ka_form");
      const booForm = document.getElementById("boo_form");

      expect(peekForm.style.display).toBe('block')
      expect(kaForm.style.display).toBe('none')
      expect(booForm.style.display).toBe('none')

    });

    it("displays appropriate content when associated tab is clicked", () =>{
      const kaForm = document.getElementById("ka_form");
      const ka = document.getElementById("ka");

      expect(kaForm.style.display).toBe('none')
      ka.click()
      expect(kaForm.style.display).toBe('block')
    });

  });
});
