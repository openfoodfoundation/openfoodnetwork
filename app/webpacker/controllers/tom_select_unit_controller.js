import TomSelectController from "./tom_select_controller.js"

export default class extends TomSelectController {
  static values = { options: Object, placeholder: String };

  connect(options = {}) {
    // Pretend sibling element is a target
    const nameInputTarget = this.element.parentNode.querySelector('[data-tom-select-unit-target=nameInput]');
    const createElementWithText = this.createElementWithText;

    nameInputTarget.addEventListener("keydown", function(e){ console.log('keydown'); e.stopPropagation(); });
    // Prevent bubbling up to tomselect, and focus. But tomselect captures it still :(
    nameInputTarget.addEventListener("click", function(e){
      console.log('click'); e.stopPropagation();
      // e.preventDefault();
      // nameInputTarget.focus();
    });
    // But tomselect seems to  captures it still, befure this is called:
    nameInputTarget.addEventListener("focus", function(e){ console.log('focus'); e.stopPropagation(); });

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
        console.log('onChange', value);
        if (value == "items") {
          nameInputTarget.focus(); //pls focus the input, I want to type into it!
          return false;
        } else {
          this.close();
        }
      },
      onDropdownClose: function(dropdown) {
        console.log("onDropdownClose", dropdown, this.getValue());
        // nameInputTarget.blur();
        const value = this.getValue()
        // if(value == "items") {
        // if (value == "boxes") { //todo: if value is not a pre-defined value

        //   this.setValue("items", true); // poopoo, silent mode still resets the input
        //   nameInputTarget.value = value; //todo: only if custom item value
        // }
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
