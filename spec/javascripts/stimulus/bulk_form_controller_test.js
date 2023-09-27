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

  describe("Modifying input values", () => {
    // Mock I18n. TODO: moved to a shared helper
    beforeAll(() => {
      const mockedT = jest.fn();
      mockedT.mockImplementation((string, opts) => (string + ', ' + JSON.stringify(opts)));

      global.I18n =  {
        t: mockedT
      };
    })
    // (jest still doesn't have aroundEach https://github.com/jestjs/jest/issues/4543 )
    afterAll(() => {
      delete global.I18n;
    })

    beforeEach(() => {
      document.body.innerHTML = `
        <div id="disable1"></div>
        <div id="disable2"></div>
        <form data-controller="bulk-form" data-bulk-form-disable-selector-value="#disable1,#disable2">
          <div id="actions" data-bulk-form-target="actions" class="hidden"></div>
          <div id="changed_summary" data-bulk-form-target="changedSummary" data-translation-key="changed_summary"></div>
          <div data-record-id="1">
            <input id="input1a" type="text" value="initial1a">
            <input id="input1b" type="text" value="initial1b">
          </div>
          <div data-record-id="2">
            <input id="input2" type="text" value="initial2">
          </div>
          <input type="submit">
        </form>
      `;

      const disable1 = document.getElementById("disable1");
      const disable2 = document.getElementById("disable2");
      const actions = document.getElementById("actions");
      const changed_summary = document.getElementById("changed_summary");
      const input1a = document.getElementById("input1a");
      const input1b = document.getElementById("input1b");
      const input2 = document.getElementById("input2");
    });

    describe("marking changed fields", () => {
      it("onChange", () => {
        input1a.value = 'updated1a';
        input1a.dispatchEvent(new Event("change"));
        // Expect only first field to show changed
        expect(input1a.classList).toContain('changed');
        expect(input1b.classList).not.toContain('changed');
        expect(input2.classList).not.toContain('changed');

        // Change back to original value
        input1a.value = 'initial1a';
        input1a.dispatchEvent(new Event("change"));
        expect(input1a.classList).not.toContain('changed');

      });

      it("onKeyup", () => {
        input1a.value = 'u1a';
        input1a.dispatchEvent(new Event("keyup"));
        // Expect only first field to show changed
        expect(input1a.classList).toContain('changed');
        expect(input1b.classList).not.toContain('changed');
        expect(input2.classList).not.toContain('changed');

        // Change back to original value
        input1a.value = 'initial1a';
        input1a.dispatchEvent(new Event("keyup"));
        expect(input1a.classList).not.toContain('changed');
      });

      it("multiple fields", () => {
        input1a.value = 'updated1a';
        input1a.dispatchEvent(new Event("change"));
        input2.value = 'updated2';
        input2.dispatchEvent(new Event("change"));
        // Expect only first field to show changed
        expect(input1a.classList).toContain('changed');
        expect(input1b.classList).not.toContain('changed');
        expect(input2.classList).toContain('changed');

        // Change only one back to original value
        input1a.value = 'initial1a';
        input1a.dispatchEvent(new Event("change"));
        expect(input1a.classList).not.toContain('changed');
        expect(input1b.classList).not.toContain('changed');
        expect(input2.classList).toContain('changed');
      });
    })

    describe("activating sections, and showing a summary", () => {
      // This scenario should probably be broken up into smaller units.
      it("counts changed records ", () => {
        // Record 1: First field changed
        input1a.value = 'updated1a';
        input1a.dispatchEvent(new Event("change"));
        // Actions and changed summary are shown, with other sections disabled
        expect(actions.classList).not.toContain('hidden');
        expect(changed_summary.textContent).toBe('changed_summary, {"count":1}');
        expect(disable1.classList).toContain('disabled-section');
        expect(disable2.classList).toContain('disabled-section');

        // Record 1: Second field changed
        input1b.value = 'updated1b';
        input1b.dispatchEvent(new Event("change"));
        // Expect to show same summary translation
        expect(actions.classList).not.toContain('hidden');
        expect(changed_summary.textContent).toBe('changed_summary, {"count":1}');

        // Record 2: has been changed
        input2.value = 'updated2';
        input2.dispatchEvent(new Event("change"));
        // Expect summary to count both records
        expect(actions.classList).not.toContain('hidden');
        expect(changed_summary.textContent).toBe('changed_summary, {"count":2}');

        // Record 1: Change first field back to original value
        input1a.value = 'initial1a';
        input1a.dispatchEvent(new Event("change"));
        // Both records are still changed.
        expect(input1a.classList).not.toContain('changed');
        expect(input1b.classList).toContain('changed');
        expect(input2.classList).toContain('changed');
        expect(actions.classList).not.toContain('hidden');
        expect(changed_summary.textContent).toBe('changed_summary, {"count":2}');

        // Record 1: Change second field back to original value
        input1b.value = 'initial1b';
        input1b.dispatchEvent(new Event("change"));
        // Both fields for record 1 show unchanged, but second record is still changed
        expect(actions.classList).not.toContain('hidden');
        expect(changed_summary.textContent).toBe('changed_summary, {"count":1}');
        expect(disable1.classList).toContain('disabled-section');
        expect(disable2.classList).toContain('disabled-section');

        // Record 2: Change back to original value
        input2.value = 'initial2';
        input2.dispatchEvent(new Event("change"));
        // Actions are hidden and other sections are now re-enabled
        expect(actions.classList).toContain('hidden');
        expect(changed_summary.textContent).toBe('changed_summary, {"count":0}');
        expect(disable1.classList).not.toContain('disabled-section');
        expect(disable2.classList).not.toContain('disabled-section');
      });
    });
  });

  describe("When there are errors", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <form data-controller="bulk-form" data-bulk-form-error-value="true">
          <div id="actions" data-bulk-form-target="actions">
            An error occurred.
            <input type="submit">
          </div>
          <div data-record-id="1">
            <input id="input1a" type="text" value="initial1a">
          </div>
        </form>
      `;

      const actions = document.getElementById("actions");
      const changed_summary = document.getElementById("changed_summary");
      const input1a = document.getElementById("input1a");
    });

    it("form actions section remains visible", () => {
      // Expect actions to remain visible
      expect(actions.classList).not.toContain('hidden');

      // Record 1: First field changed
      input1a.value = 'updated1a';
      input1a.dispatchEvent(new Event("change"));
      // Expect actions to remain visible
      expect(actions.classList).not.toContain('hidden');

      // Change back to original value
      input1a.value = 'initial1a';
      input1a.dispatchEvent(new Event("change"));
      // Expect actions to remain visible
      expect(actions.classList).not.toContain('hidden');
    });
  });

  // unable to test disconnect at this stage
  // describe("disconnect()", () => {
  //   it("resets other elements", () => {
  //     const disable1 = document.getElementById("disable1");
  //     const disable2 = document.getElementById("disable2");
  //     const controller = document.querySelector('[data-controller="bulk-form"]');
  //     const form = document.querySelector('[data-controller="bulk-form"]');

  //     // Form is changed and other sections are disabled
  //     input1a.value = 'updated1a';
  //     input1a.dispatchEvent(new Event("change"));
  //     expect(disable1.classList).toContain('disabled-section');
  //     expect(disable2.classList).toContain('disabled-section');

  //     // form.submit(); //not implemented
  //     document.body.removeChild(controller); //doesn't trigger disconnect
  //     controller.innerHTML = ''; //doesn't trigger disconnect

  //     expect(disable1.classList).not.toContain('disabled-section');
  //     expect(disable2.classList).not.toContain('disabled-section');
  //     //TODO: expect window to have no beforeunload event listener
  //   });
  // });
});
