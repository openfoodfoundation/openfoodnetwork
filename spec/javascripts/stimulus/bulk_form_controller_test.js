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
      <form data-controller="bulk-form">
        <div id="modified_summary" data-bulk-form-target="modifiedSummary" data-translation-key="modified_summary"></div>
        <div data-record-id="1">
          <input id="input1a" type="text" value="initial1a">
          <input id="input1b" type="text" value="initial1b">
        </div>
        <div data-record-id="2">
          <input id="input2" type="text" value="initial2">
        </div>
      </form>
    `;
  });

  describe("Modifying input values", () => {
    // This is more of a behaviour spec. Jest doesn't have all the niceties of RSpec so lots of code
    // would be repeated if these were broken into multiple examples. So it seems impractical to
    // write individual unit tests.
    it("counts modified fields and records", () => {
      const modified_summary = document.getElementById("modified_summary");
      const input1a = document.getElementById("input1a");
      const input1b = document.getElementById("input1b");
      const input2 = document.getElementById("input2");

      // Record 1: First field changed (we're not simulating a user in a browser here; we're testing DOM events directly)
      input1a.value = 'updated1a';
      input1a.dispatchEvent(new Event("change"));
      // Expect only first field to show modified, and show modified summary translation
      expect(input1a.classList).toContain('modified');
      expect(input1b.classList).not.toContain('modified');
      expect(input2.classList).not.toContain('modified');
      expect(modified_summary.textContent).toBe('modified_summary, {"count":1}');

      // Record 1: Second field changed
      input1b.value = 'updated1b';
      input1b.dispatchEvent(new Event("change"));
      // Expect to show modified, and same summary translation
      expect(input1a.classList).toContain('modified');
      expect(input1b.classList).toContain('modified');
      expect(input2.classList).not.toContain('modified');
      expect(modified_summary.textContent).toBe('modified_summary, {"count":1}');

      // Record 2: has been changed
      input2.value = 'updated2';
      input2.dispatchEvent(new Event("change"));
      // Expect all fields to show modified, summary counts both records
      expect(input1a.classList).toContain('modified');
      expect(input1b.classList).toContain('modified');
      expect(input2.classList).toContain('modified');
      expect(modified_summary.textContent).toBe('modified_summary, {"count":2}');

      // Record 1: Change first field back to original value
      input1a.value = 'initial1a';
      input1a.dispatchEvent(new Event("change"));
      // Expect first field to not show modified. But both records are still modified.
      expect(input1a.classList).not.toContain('modified');
      expect(input1b.classList).toContain('modified');
      expect(input2.classList).toContain('modified');
      expect(modified_summary.textContent).toBe('modified_summary, {"count":2}');

      // Record 1: Change second field back to original value
      input1b.value = 'initial1b';
      input1b.dispatchEvent(new Event("change"));
      // Both fields for record 1 show unmodified, but second record is still modified
      expect(input1a.classList).not.toContain('modified');
      expect(input1b.classList).not.toContain('modified');
      expect(input2.classList).toContain('modified');
      expect(modified_summary.textContent).toBe('modified_summary, {"count":1}');

      // Record 2: Change back to original value
      input2.value = 'initial2';
      input2.dispatchEvent(new Event("change"));
      // No fields or records are modified
      expect(input1a.classList).not.toContain('modified');
      expect(input1b.classList).not.toContain('modified');
      expect(input2.classList).not.toContain('modified');
      expect(modified_summary.textContent).toBe('modified_summary, {"count":0}');
    });
  });
});
