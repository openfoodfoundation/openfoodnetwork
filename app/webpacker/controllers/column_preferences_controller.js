import { Controller } from "stimulus";

// Manage column visibility according to checkbox selection
//
export default class ColumnPreferencesController extends Controller {
  connect() {
    this.checkboxes = this.element.querySelectorAll("input[type=checkbox]");

    for (const element of this.checkboxes) {
      // On initial load
      this.#showHideColumn(element);
      // On checkbox changed
      element.addEventListener("change", this.#showHideColumn.bind(this));
    }
  }

  // private

  #showHideColumn(e) {
    const element = e.target || e;
    const name = element.dataset.columnName;
    const selector = `col[data-column-preferences-name="${name}"]`;
    const column = document.querySelector(selector);
    const index = this.#getIndex(column);

    if (column == null) {
      console.error(`ColumnPreferencesController: could not find ${selector}`);
      return;
    }

    // Hide column definition
    this.#showHideElement(column, element.checked);

    // Hide each cell in column (ignore rows with colspan)
    const rows = column.closest("table").querySelectorAll("tr:not(:has(td[colspan]))");
    rows.forEach((row) => {
      // Ignore cell if spanning multiple columns
      const cell = row.children[index];
      if (cell == undefined) return;

      this.#showHideElement(cell, element.checked);
    });
  }

  #getIndex(column) {
    return Array.from(column.parentNode.children).indexOf(column);
  }

  #showHideElement(element, show) {
    element.style.display = show ? "" : "none";
  }
}
