import { Controller } from "stimulus";

// Manage column visibility according to checkbox selection
//
export default class ColumnPreferencesController extends Controller {
  connect() {
    this.table = document.querySelector('table[data-column-preferences-target="table"]');
    this.cols = Array.from(this.table.querySelectorAll("col"));
    this.colSpanCells = Array.from(this.table.querySelectorAll("th[colspan],td[colspan]"));
    // Initialise data-default-col-span
    this.colSpanCells.forEach((cell) => {
      cell.dataset.defaultColSpan ||= cell.colSpan;
    });

    this.checkboxes = Array.from(this.element.querySelectorAll("input[type=checkbox]"));
    for (const element of this.checkboxes) {
      // On initial load
      this.#showHideColumn(element);
      // On checkbox changed
      element.addEventListener("change", this.#showHideColumn.bind(this));
    }

    this.#observeProductsTableRows();
  }

  // private

  #showHideColumn(e) {
    const element = e.target || e;
    const name = element.dataset.columnName;

    // Css defined in app/webpacker/css/admin/products_v3.scss
    this.table.classList.toggle(`hide-${name}`, !element.checked);

    // Reset cell colspans
    for (const cell of this.colSpanCells) {
      this.#updateColSpanCell(cell);
    }
  }

  #showHideElement(element, show) {
    element.style.display = show ? "" : "none";
  }

  #observeProductsTableRows() {
    this.productsTableObserver = new MutationObserver((mutations, _observer) => {
      const mutationRecord = mutations[0];

      if (mutationRecord) {
        const productRowElement = mutationRecord.addedNodes[0];

        if (productRowElement) {
          const newColSpanCell = productRowElement.querySelector("td[colspan]");
          newColSpanCell.dataset.defaultColSpan ||= newColSpanCell.colSpan;
          this.#updateColSpanCell(newColSpanCell);
          this.colSpanCells.push(newColSpanCell);
        }
      }
    });

    this.productsTableObserver.observe(this.table, { childList: true });
  }

  #hiddenColCount() {
    return this.checkboxes.filter((checkbox) => !checkbox.checked).length;
  }

  #updateColSpanCell(cell) {
    cell.colSpan = parseInt(cell.dataset.defaultColSpan, 10) - this.#hiddenColCount();
  }
}
