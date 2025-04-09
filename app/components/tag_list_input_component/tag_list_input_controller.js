import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["tagList", "newTag", "template", "list"];
  static values = { highlightClass: String };

  addTag() {
    // add to tagList
    this.tagListTarget.value = this.tagListTarget.value.concat(`,${this.newTagTarget.value}`);

    // Create new li component with value
    const newTagElement = this.templateTarget.content.cloneNode(true);
    const spanElement = newTagElement.querySelector("span");
    spanElement.innerText = this.newTagTarget.value;
    this.listTarget.appendChild(newTagElement);

    this.#highlightList();

    // Clear new tag value
    this.newTagTarget.value = "";
  }

  removeTag(event) {
    // Text to remove
    const tagName = event.srcElement.previousElementSibling.textContent;

    // Remove tag from list
    const tags = this.tagListTarget.value.split(",");
    const index = tags.indexOf(tagName);
    tags.splice(index, 1);
    this.tagListTarget.value = tags.join(",");

    // manualy dispatch an Input event so the change gets picked up by the bulk form controller
    this.tagListTarget.dispatchEvent(new InputEvent("input"));
    this.#highlightList();

    // Remove HTML element from the list
    event.srcElement.parentElement.parentElement.remove();
  }

  // Strip comma from tag name
  filterInput(event) {
    if (event.key === ",") {
      event.srcElement.value = event.srcElement.value.replace(",", "");
    }
  }

  // private

  #highlightList() {
    if (this.highlightClassValue !== "") {
      // div with the tags class
      const tagsInputDiv = this.tagListTarget.nextElementSibling.firstElementChild;
      tagsInputDiv.classList.add(this.highlightClassValue);
    }
  }
}
