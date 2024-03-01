import TomSelectController from "./tom_select_controller.js"

export default class extends TomSelectController {
  static values = { options: Object, placeholder: String };

  connect(options = {}) {
    // Pretend sibling element is a target
    const nameInputTarget = this.element.parentNode.querySelector('[data-tom-select-unit-target=nameInput]');
    const createElementWithText = this.createElementWithText;

    options = {
      render: {
        // Render item option with its associate input
        option: function(data, escape) {
          const div = createElementWithText("div", escape(data.text));

          if(data.value == "items") {
            div.appendChild(nameInputTarget);
          }

          return div;
        },
      },
      plugins: [],
      ...options,
    };

    super.connect(options);
  }

  createElementWithText(tagName, text) {
    const element = document.createElement(tagName);
    element.appendChild(document.createTextNode(text));
    return element;
  }
}
