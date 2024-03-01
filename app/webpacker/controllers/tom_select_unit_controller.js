import TomSelectController from "./tom_select_controller.js"

export default class extends TomSelectController {
  static values = { options: Object, placeholder: String };

  connect(options = {}) {
    // Pretend sibling element is a target
    const nameInputTarget = this.element.parentNode.querySelector('[data-tom-select-unit-target=nameInput]');
    const createElementWithText = this.createElementWithText;

    options = {
      closeAfterSelect: false,
      searchField: [], //disable type to search. todo: copy for a no-input controller
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
      onChange: function(value) {
        if (value == "items") {
          console.log('onChange', value);
          nameInputTarget.focus(); //pls focus the input, I want to type into it!
          return false;
        }
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
