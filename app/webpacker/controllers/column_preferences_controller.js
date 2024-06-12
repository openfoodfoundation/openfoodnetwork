import { Controller } from "stimulus";

// Manage column visibility according to checkbox selection
//
export default class ColumnPreferencesController extends Controller {
  connect() {
    this.table = document.querySelector('table[data-column-preferences-target="table"]');
    this.cols = Array.from(this.table.querySelectorAll('col'));
    this.colSpanCells = this.table.querySelectorAll('th[colspan],td[colspan]');
    // Initialise data-default-col-span
    this.colSpanCells.forEach((cell)=> {
      cell.dataset.defaultColSpan ||= cell.colSpan;
    });

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
    const column = this.table.querySelector(selector);
    const index = this.#getIndex(column);

    if (column == null) {
      console.error(`ColumnPreferencesController: could not find ${selector}`);
      return;
    }

    // Hide column definition
    this.#showHideElement(column, element.checked);

    // Hide each cell in column (ignore rows with colspan)
    const rows = this.table.querySelectorAll("tr:not(:has(td[colspan]))");
    rows.forEach((row) => {
      // Ignore cell if spanning multiple columns
      const cell = row.children[index];
      if (cell == undefined) return;

      this.#showHideElement(cell, element.checked);
    });

    // Reset cell colspans
    const hiddenColCount = this.cols.filter((col)=> col.style.display == 'none').length;
    for(const cell of this.colSpanCells) {
      const span = parseInt(cell.dataset.defaultColSpan, 10) - hiddenColCount;
      cell.colSpan = span;
    };
  }

  #getIndex(column) {
    return Array.from(column.parentNode.children).indexOf(column);
  }

  #showHideElement(element, show) {
    element.style.display = show ? "" : "none";
  }
}
