import TomSelect from "./tom_select_controller";

const minimumOptionsForSearchField = 11;

export default class extends TomSelect {
  static values = { options: Object, placeholder: String };

  connect(options = {}) {
    const template = this.template();
    let additional_options = {};
    const lines_of_option = template.content.children.length; 

    if (lines_of_option < minimumOptionsForSearchField) {
      additional_options.plugins = [];  
    }

    super.connect(additional_options);
    this.control.on('focus', this.fetchProducers.bind(this));
  }

  disconnect() {
    if (this.control) this.control.destroy();
  }
  
  fetchProducers() {
    if ((Object.keys(this.control.options).length) > 1) return false;

    const template = this.template();
    Array.from(template.content.children).forEach((option) => {
      this.control.addOption({value: option.value, text: option.text});
    }); 
  }
  
  template() {
    return document.querySelector("#producer_options");
  }
}
