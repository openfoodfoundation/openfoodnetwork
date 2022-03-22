import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  reflex = "SelectorComponent";

  connect() {
    super.connect();
    window.addEventListener("click", this.closeOnClickOutside);
    this.computeItemsHeight();
  }

  disconnect() {
    super.disconnect();
    window.removeEventListener("click", this.closeOnClickOutside);
  }

  closeOnClickOutside = (event) => {
    if (!this.element.contains(event.target)) {
      this.stimulate(`${this.reflex}#close`, this.element);
    }
  };

  computeItemsHeight = () => {
    const items = this.element.querySelector(".selector-items");
    const rect = items.getBoundingClientRect();
    items.style.maxHeight = `calc(100vh - ${rect.height}px)`;
  };
}
