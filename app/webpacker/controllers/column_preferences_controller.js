import { Controller } from "stimulus";


// Manage column visibility according to checkbox selection
//
export default class ColumnPreferencesController extends Controller {
  connect() {
    this.checkboxes = this.element.querySelectorAll('input[type=checkbox]');

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

    if (column == null) {
      console.error(`ColumnPreferencesController: could not find ${selector}`);
      return;
    }

    column.style.visibility = (element.checked ? '' : 'collapse');
  }
}
