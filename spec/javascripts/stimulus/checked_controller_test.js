/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import checked_controller from "../../../app/webpacker/controllers/checked_controller";

describe("CheckedController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("checked", checked_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="checked">
        <input
          id="selectAllCheckbox"
          type="checkbox"
          data-action="change->checked#toggleAll"
          data-checked-target="all">
        <input
          id="checkboxA"
          type="checkbox"
          data-action="change->checked#toggleCheckbox"
          data-checked-target="checkbox">
        <input
          id="checkboxB"
          type="checkbox"
          data-action="change->checked#toggleCheckbox"
          data-checked-target="checkbox">
      </div>
    `;
  });

  describe("#toggleAll", () => {
    it("checks all checkboxes when it's checked and unchecks them all when unchecked", () => {
      const selectAllCheckbox = document.getElementById("selectAllCheckbox");
      const checkboxA = document.getElementById("checkboxA");
      const checkboxB = document.getElementById("checkboxB");
      expect(selectAllCheckbox.checked).toBe(false);
      expect(checkboxA.checked).toBe(false);
      expect(checkboxB.checked).toBe(false);

      selectAllCheckbox.click()

      expect(selectAllCheckbox.checked).toBe(true);
      expect(checkboxA.checked).toBe(true);
      expect(checkboxB.checked).toBe(true);

      selectAllCheckbox.click()

      expect(selectAllCheckbox.checked).toBe(false);
      expect(checkboxA.checked).toBe(false);
      expect(checkboxB.checked).toBe(false);
    });
  });

  describe("#toggleCheckbox", () => {
    it("checks the individual checkbox and checks the select all checkbox if all checkboxes are checked and vice versa", () => {
      const selectAllCheckbox = document.getElementById("selectAllCheckbox");
      const checkboxA = document.getElementById("checkboxA");
      const checkboxB = document.getElementById("checkboxB");
      checkboxA.click()
      expect(selectAllCheckbox.checked).toBe(false);
      expect(checkboxA.checked).toBe(true);
      expect(checkboxB.checked).toBe(false);

      checkboxB.click()

      expect(selectAllCheckbox.checked).toBe(true);
      expect(checkboxA.checked).toBe(true);
      expect(checkboxB.checked).toBe(true);

      checkboxB.click()

      expect(selectAllCheckbox.checked).toBe(false);
      expect(checkboxA.checked).toBe(true);
      expect(checkboxB.checked).toBe(false);
    });
  });

  describe("#connect", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="checked">
          <input
            id="selectAllCheckbox"
            type="checkbox"
            data-action="change->checked#toggleAll"
            data-checked-target="all">
          <input
            id="checkboxA"
            type="checkbox"
            data-action="change->checked#toggleCheckbox"
            data-checked-target="checkbox"
            checked="checked">
          <input
            id="checkboxB"
            type="checkbox"
            data-action="change->checked#toggleCheckbox"
            data-checked-target="checkbox"
            checked="checked">
        </div>
      `;
    });

    it("checks the select all checkbox on page load if all checkboxes are checked", () => {
      const selectAllCheckbox = document.getElementById("selectAllCheckbox");
      expect(selectAllCheckbox.checked).toBe(true);
    });
  });
});
