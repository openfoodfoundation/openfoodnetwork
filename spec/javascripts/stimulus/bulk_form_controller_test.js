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
        <div id="modified_summary" data-bulk-form-target="modifiedSummary" data-translation-key="modified_summary"></div>
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
  });

  describe("Modifying input values", () => {
    // This is more of a behaviour spec. Jest doesn't have all the niceties of RSpec so lots of code
    // would be repeated if these were broken into multiple examples. So it seems impractical to
    // write individual unit tests.
    it("counts modified fields and records", () => {
      const disable1 = document.getElementById("disable1");
      const disable2 = document.getElementById("disable2");
      const actions = document.getElementById("actions");
      const modified_summary = document.getElementById("modified_summary");
      const input1a = document.getElementById("input1a");
      const input1b = document.getElementById("input1b");
      const input2 = document.getElementById("input2");

      // Record 1: First field changed (we're not simulating a user in a browser here; we're testing DOM events directly)
      input1a.value = 'updated1a';
      input1a.dispatchEvent(new Event("change"));
      // Expect only first field to show modified
      expect(input1a.classList).toContain('modified');
      expect(input1b.classList).not.toContain('modified');
      expect(input2.classList).not.toContain('modified');
      // Actions and modified summary are shown, with other sections disabled
      expect(actions.classList).not.toContain('hidden');
      expect(modified_summary.textContent).toBe('modified_summary, {"count":1}');
      expect(disable1.classList).toContain('disabled-section');
      expect(disable2.classList).toContain('disabled-section');

      // Record 1: Second field changed
      input1b.value = 'updated1b';
      input1b.dispatchEvent(new Event("change"));
      // Expect to show modified, and same summary translation
      expect(input1a.classList).toContain('modified');
      expect(input1b.classList).toContain('modified');
      expect(input2.classList).not.toContain('modified');
      expect(actions.classList).not.toContain('hidden');
      expect(modified_summary.textContent).toBe('modified_summary, {"count":1}');

      // Record 2: has been changed
      input2.value = 'updated2';
      input2.dispatchEvent(new Event("change"));
      // Expect all fields to show modified, summary counts both records
      expect(input1a.classList).toContain('modified');
      expect(input1b.classList).toContain('modified');
      expect(input2.classList).toContain('modified');
      expect(actions.classList).not.toContain('hidden');
      expect(modified_summary.textContent).toBe('modified_summary, {"count":2}');

      // Record 1: Change first field back to original value
      input1a.value = 'initial1a';
      input1a.dispatchEvent(new Event("change"));
      // Expect first field to not show modified. But both records are still modified.
      expect(input1a.classList).not.toContain('modified');
      expect(input1b.classList).toContain('modified');
      expect(input2.classList).toContain('modified');
      expect(actions.classList).not.toContain('hidden');
      expect(modified_summary.textContent).toBe('modified_summary, {"count":2}');

      // Record 1: Change second field back to original value
      input1b.value = 'initial1b';
      input1b.dispatchEvent(new Event("change"));
      // Both fields for record 1 show unmodified, but second record is still modified
      expect(input1a.classList).not.toContain('modified');
      expect(input1b.classList).not.toContain('modified');
      expect(input2.classList).toContain('modified');
      expect(actions.classList).not.toContain('hidden');
      expect(modified_summary.textContent).toBe('modified_summary, {"count":1}');
      expect(disable1.classList).toContain('disabled-section');
      expect(disable2.classList).toContain('disabled-section');

      // Record 2: Change back to original value
      input2.value = 'initial2';
      input2.dispatchEvent(new Event("change"));
      // No fields or records are modified
      expect(input1a.classList).not.toContain('modified');
      expect(input1b.classList).not.toContain('modified');
      expect(input2.classList).not.toContain('modified');
      // Actions are hidden and other sections are now re-enabled
      expect(actions.classList).toContain('hidden');
      expect(modified_summary.textContent).toBe('modified_summary, {"count":0}');
      expect(disable1.classList).not.toContain('disabled-section');
      expect(disable2.classList).not.toContain('disabled-section');
    });
  });

  // unable to test disconnect at this stage
  // describe("disconnect()", () => {
  //   it("resets other elements", () => {
  //     const disable1 = document.getElementById("disable1");
  //     const disable2 = document.getElementById("disable2");
  //     const controller = document.querySelector('[data-controller="bulk-form"]');
  //     const form = document.querySelector('[data-controller="bulk-form"]');

  //     // Form is modified and other sections are disabled
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
