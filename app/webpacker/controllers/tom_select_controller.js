import { Controller } from "stimulus";
import TomSelect from "tom-select/dist/esm/tom-select.complete";

export default class extends Controller {
  static values = { options: Object };
  static defaults = {
    maxItems: 1,
    maxOptions: null,
    plugins: ["dropdown_input"],
    allowEmptyOption: true,
    closeAfterSelect: true,
    onItemAdd: function () {
      this.setTextboxValue("");
    },
  };

  connect(options = {}) {
    if (this.#placeholder()) {
      options.allowEmptyOption = false;
      options.placeholder = this.#placeholder();
    }

    this.control = new TomSelect(this.element, {
      ...this.constructor.defaults,
      ...this.optionsValue,
      ...options,
    });
  }

  disconnect() {
    if (this.control) this.control.destroy();
  }

  // private

  #placeholder() {
    const optionsArray = [...this.element.options];
    return optionsArray.find((option) => [null, ""].includes(option.value))?.text;
  }
}
