/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import updateinput_controller from "../../../app/webpacker/controllers/updateinput_controller";

describe("updateInput controller", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("updateinput", updateinput_controller);
  });

  describe("#update", () => {
    beforeEach(() => {
      document.body.innerHTML = `<form data-controller="updateinput">
        <input id="input" type="hidden" value="false" data-updateinput-target="input" />
        <div id="submit" data-action="click->updateinput#update" data-updateinput-value="true" />
      </form>`;
    });

    it("update the input value", () => {
      const submit = document.getElementById("submit");
      const input = document.getElementById("input");
      expect(input.value).toBe("false");

      submit.click();

      expect(input.value).toBe("true");
    });
  });
});
