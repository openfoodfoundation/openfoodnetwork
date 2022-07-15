/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import select_all_controller from "../../../app/webpacker/controllers/select_all_controller";

describe("SelectAllController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("select-all", select_all_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="select-all">
        <input
          id="selectAllCheckbox"
          type="checkbox"
          data-action="change->select-all#toggleAll"
          data-select-all-target="all">
        <input
          id="checkboxA"
          type="checkbox"
          data-action="change->select-all#toggleCheckbox"
          data-select-all-target="checkbox">
        <input
          id="checkboxB"
          type="checkbox"
          data-action="change->select-all#toggleCheckbox"
          data-select-all-target="checkbox">
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
});
