import SelectorController from "./selector_controller"

export default class extends SelectorController {
  static targets = ["items"];

  filter = (event) => {
    const query = event.target.value;

    this.itemsTargets.forEach((el, i) => {
      el.style.display = el.textContent.toLowerCase().includes(query)
        ? ""
        : "none";
    });
  };
}
