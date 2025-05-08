import { Controller } from "stimulus";
import TomSelect from "tom-select/dist/esm/tom-select.complete";

export default class extends Controller {
  static values = { options: Object, placeholder: String };

  connect(options = {}) {
    this.control = new TomSelect(this.element, {
      maxItems: 1,
      maxOptions: null,
      plugins: ["dropdown_input"],
      allowEmptyOption: true, // Show blank option (option with empty value)
      placeholder: this.placeholderValue || this.#emptyOption(),
      onItemAdd: function () {
        this.setTextboxValue("");
      },
      ...this.optionsValue,
      ...options,
    });
  }

  disconnect() {
    if (this.control) this.control.destroy();
  }

  // private

  #emptyOption() {
    const optionsArray = [...this.element.options];
    return optionsArray.find((option) => [null, ""].includes(option.value))?.text;
  }
}
