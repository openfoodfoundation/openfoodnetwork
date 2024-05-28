import TomSelect from "./tom_select_controller";

const minimumOptionsForSearchField = 11;

export default class extends TomSelect {
  static values = { templateId: String, placeholder: String };

  connect() {
    const template = this.template(this.templateIdValue );
    let additional_options = {};
    const lines_of_option = template.content.children.length; 

    // Disable search input ("dropdown_input" plugin) from tom-select
    if (lines_of_option < minimumOptionsForSearchField) {
      additional_options.plugins = [];  
    }

    super.connect(additional_options);
    // focus event available on tom-select , not on html select
    this.control.on('focus', this.fetchProducers.bind(this));
  }

  disconnect() {
    if (this.control) this.control.destroy();
  }
  
  fetchProducers() {
    if ((Object.keys(this.control.options).length) > 1) return false;

    const template = this.template(this.templateIdValue );
    Array.from(template.content.children).forEach((option) => {
      this.control.addOption({value: option.value, text: option.text});
    }); 
  }
  
  template(id) {
    return document.querySelector(`#${id}`);
  }
}
