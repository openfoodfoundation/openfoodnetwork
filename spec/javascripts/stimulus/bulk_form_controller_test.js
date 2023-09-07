/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import bulk_form_controller from "../../../app/webpacker/controllers/bulk_form_controller";

describe("BulkFormController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("bulk-form", bulk_form_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <form data-controller="bulk-form">
        <input id="input1" type="text" value="initial1">
        <input id="input2" type="text" value="initial2">
      </form>
    `;
  });

  describe("#toggleModified", () => {
    it("marks a changed element as modified", () => {
      // const form = document.getElementsByTagName("form")[0];
      const input1 = document.getElementById("input1");
      const input2 = document.getElementById("input2");

      expect(input1.classList).not.toContain('modified');
      expect(input2.classList).not.toContain('modified');

      // Value has been changed (we're not simulating a user in a browser here; we're testing DOM events directly)
      input1.value = 'updated1';
      input1.dispatchEvent(new Event("change"));
      // form.dispatchEvent(new Event("change"));

      expect(input1.classList).toContain('modified');
      expect(input2.classList).not.toContain('modified');

      // Change back to original value
      input1.value = 'initial1';
      input1.dispatchEvent(new Event("change"));
      // form.dispatchEvent(new Event("change"));

      expect(input1.classList).not.toContain('modified');
      expect(input2.classList).not.toContain('modified');
    });
  });
});
