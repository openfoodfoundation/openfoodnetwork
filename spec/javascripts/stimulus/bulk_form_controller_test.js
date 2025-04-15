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
      mockedT.mockImplementation((string, opts) => string + ", " + JSON.stringify(opts));

      global.I18n = {
        t: mockedT,
      };
    });
    // (jest still doesn't have aroundEach https://github.com/jestjs/jest/issues/4543 )
    afterAll(() => {
      delete global.I18n;
    });

    beforeEach(() => {
      document.body.innerHTML = `
        <form id="disable1"><input id="disable1_element"></form>
        <div id="disable2"><form><input id="disable2_element"></form></div>
        <form data-controller="bulk-form" data-bulk-form-disable-selector-value="#disable1,#disable2">
          <div id="actions" data-bulk-form-target="actions" class="hidden"></div>
          <div id="changed_summary" data-bulk-form-target="changedSummary" data-translation-key="changed_summary"></div>
          <table class="products">
            <div data-record-id="1">
              <input id="input1a" type="text" value="initial1a">
              <input id="input1b" type="text" value="initial1b">
              <select id="select1">
                <option>one</option>
                <option selected>two</option>
              </select>
              <button>a button is counted as a form element, but value is undefined</button>
            </div>
            <div data-record-id="2">
              <input id="input2" type="text" value="initial2">
            </div>
            <input type="submit">
          </table>
        </form>
      `;
    });

    describe("marking changed fields", () => {
      it("input: onInput", () => {
        input1a.value = "updated1a";
        input1a.dispatchEvent(new Event("input"));
        // Expect only first field to show changed
        expect(input1a.classList).toContain("changed");
        expect(input1b.classList).not.toContain("changed");
        expect(input2.classList).not.toContain("changed");

        // Change back to original value
        input1a.value = "initial1a";
        input1a.dispatchEvent(new Event("input"));
        expect(input1a.classList).not.toContain("changed");
      });

      it("select: onInput", () => {
        // Select a different option (it's the only way in Jest..)
        select1.options[0].selected = true;
        select1.options[1].selected = false;
        select1.dispatchEvent(new Event("input"));
        // Expect select to show changed
        expect(input1a.classList).not.toContain("changed");
        expect(input1b.classList).not.toContain("changed");
        expect(select1.classList).toContain("changed");

        // Change back to original value
        select1.options[0].selected = false;
        select1.options[1].selected = true;
        select1.dispatchEvent(new Event("input"));
        expect(select1.classList).not.toContain("changed");
      });

      it("multiple fields", () => {
        input1a.value = "updated1a";
        input1a.dispatchEvent(new Event("input"));
        input2.value = "updated2";
        input2.dispatchEvent(new Event("input"));
        // Expect only first field to show changed
        expect(input1a.classList).toContain("changed");
        expect(input1b.classList).not.toContain("changed");
        expect(input2.classList).toContain("changed");

        // Change only one back to original value
        input1a.value = "initial1a";
        input1a.dispatchEvent(new Event("input"));
        expect(input1a.classList).not.toContain("changed");
        expect(input1b.classList).not.toContain("changed");
        expect(input2.classList).toContain("changed");
      });

      describe("select not include_blank", () => {
        beforeEach(() => {
          document.body.innerHTML = `
            <form data-controller="bulk-form" data-bulk-form-disable-selector-value="#disable1,#disable2">
              <table class="products">
                <div data-record-id="1">
                  <select id="select1">
                    <option value="1">one</option>
                    <option value="2">two</option>
                  </select>
                </div>
                <input type="submit">
              </table>
            </form>
          `;
        });

        it("shows as changed", () => {
          // Expect select to show changed (select-one always has something selected)
          expect(select1.classList).toContain("changed");

          // Change selection
          select1.options[0].selected = false;
          select1.options[1].selected = true;
          select1.dispatchEvent(new Event("input"));
          expect(select1.classList).toContain("changed");
        });
      });

      describe("select-one with include_blank", () => {
        beforeEach(() => {
          document.body.innerHTML = `
            <form data-controller="bulk-form" data-bulk-form-disable-selector-value="#disable1,#disable2">
              <table class="products">
                <div data-record-id="1">
                  <select id="select1">
                    <option value="">blank</option>
                    <option value="1">one</option>
                  </select>
                </div>
                <input type="submit">
              </table>
            </form>
          `;
        });

        it("does not show as changed", () => {
          expect(select1.classList).not.toContain("changed");

          // Change selection
          select1.options[0].selected = false;
          select1.options[1].selected = true;
          select1.dispatchEvent(new Event("input"));
          expect(select1.classList).toContain("changed");
        });
      });
    });

    describe("activating sections, and showing a summary", () => {
      // This scenario should probably be broken up into smaller units.
      it("counts changed records ", () => {
        // Record 1: First field changed
        input1a.value = "updated1a";
        input1a.dispatchEvent(new Event("input"));
        // Actions and changed summary are shown, with other sections disabled
        expect(actions.classList).not.toContain("hidden");
        expect(changed_summary.textContent).toBe('changed_summary, {"count":1}');
        expect(disable1.classList).toContain("disabled-section");
        expect(disable1_element.disabled).toBe(true);
        expect(disable2.classList).toContain("disabled-section");
        expect(disable2_element.disabled).toBe(true);

        // Record 1: Second field changed
        input1b.value = "updated1b";
        input1b.dispatchEvent(new Event("input"));
        // Expect to show same summary translation
        expect(actions.classList).not.toContain("hidden");
        expect(changed_summary.textContent).toBe('changed_summary, {"count":1}');

        // Record 2: has been changed
        input2.value = "updated2";
        input2.dispatchEvent(new Event("input"));
        // Expect summary to count both records
        expect(actions.classList).not.toContain("hidden");
        expect(changed_summary.textContent).toBe('changed_summary, {"count":2}');

        // Record 1: Change first field back to original value
        input1a.value = "initial1a";
        input1a.dispatchEvent(new Event("input"));
        // Both records are still changed.
        expect(input1a.classList).not.toContain("changed");
        expect(input1b.classList).toContain("changed");
        expect(input2.classList).toContain("changed");
        expect(actions.classList).not.toContain("hidden");
        expect(changed_summary.textContent).toBe('changed_summary, {"count":2}');

        // Record 1: Change second field back to original value
        input1b.value = "initial1b";
        input1b.dispatchEvent(new Event("input"));
        // Both fields for record 1 show unchanged, but second record is still changed
        expect(actions.classList).not.toContain("hidden");
        expect(changed_summary.textContent).toBe('changed_summary, {"count":1}');
        expect(disable1.classList).toContain("disabled-section");
        expect(disable1_element.disabled).toBe(true);
        expect(disable2.classList).toContain("disabled-section");
        expect(disable2_element.disabled).toBe(true);

        // Record 2: Change back to original value
        input2.value = "initial2";
        input2.dispatchEvent(new Event("input"));
        // Actions are hidden and other sections are now re-enabled
        expect(actions.classList).toContain("hidden");
        expect(changed_summary.textContent).toBe('changed_summary, {"count":0}');
        expect(disable1.classList).not.toContain("disabled-section");
        expect(disable1_element.disabled).toBe(false);
        expect(disable2.classList).not.toContain("disabled-section");
        expect(disable2_element.disabled).toBe(false);
      });
    });
  });

  describe("When there are errors", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <form data-controller="bulk-form" data-bulk-form-error-value="true">
          <table class="products">
            <div id="actions" data-bulk-form-target="actions">
              An error occurred.
              <input type="submit">
            </div>
            <div data-record-id="1">
              <input id="input1a" type="text" value="initial1a">
            </div>
          </table>
        </form>
      `;

      const actions = document.getElementById("actions");
      const changed_summary = document.getElementById("changed_summary");
      const input1a = document.getElementById("input1a");
    });

    it("form actions section remains visible", () => {
      // Expect actions to remain visible
      expect(actions.classList).not.toContain("hidden");

      // Record 1: First field changed
      input1a.value = "updated1a";
      input1a.dispatchEvent(new Event("input"));
      // Expect actions to remain visible
      expect(actions.classList).not.toContain("hidden");

      // Change back to original value
      input1a.value = "initial1a";
      input1a.dispatchEvent(new Event("input"));
      // Expect actions to remain visible
      expect(actions.classList).not.toContain("hidden");
    });
  });

  describe("Adding new fields", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <form id="form" data-controller="bulk-form" data-action="custom-event->bulk-form#registerElements",
          <table class="products">
            <div data-record-id="1">
              <input id="input1a" type="text" value="initial1a">
              <template id="template">
                <input id="input1b" type="text" value="initial1b">
              </template>
            </div>
            <div data-record-id="2">
              <input id="input2" type="text" value="initial2">
            </div>
            <input type="submit">
          </table>
        </form>
      `;
    });

    describe("registerElements", () => {
      beforeEach(() => {
        // Add new field after controller has initialised
        input1a.insertAdjacentHTML("afterend", template.innerHTML);

        // Trigger bulk-form#registerElements
        form.dispatchEvent(new Event("custom-event"));
      });

      it("onInput", () => {
        input1b.value = "updated1b";
        input1b.dispatchEvent(new Event("input"));
        // Expect only updated field to show changed
        expect(input1b.classList).toContain("changed");
        expect(input2.classList).not.toContain("changed");

        // Change back to original value
        input1b.value = "initial1b";
        input1b.dispatchEvent(new Event("input"));
        expect(input1b.classList).not.toContain("changed");
      });
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
