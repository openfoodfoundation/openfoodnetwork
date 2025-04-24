import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["tagList", "newTag", "template", "list"];

  addTag(event) {
    // prevent hotkey form submitting the form (default action for "enter" key)
    event.preventDefault();

    // Check if tag already exist
    const newTagName = this.newTagTarget.value.trim();
    if (newTagName.length == 0) {
      return;
    }

    const tags = this.tagListTarget.value.split(",");
    const index = tags.indexOf(newTagName);
    if (index != -1) {
      // highlight the value in red
      this.newTagTarget.classList.add("tag-error");
      return;
    }

    // add to tagList
    this.tagListTarget.value = this.tagListTarget.value.concat(`,${newTagName}`);

    // Create new li component with value
    const newTagElement = this.templateTarget.content.cloneNode(true);
    const spanElement = newTagElement.querySelector("span");
    spanElement.innerText = newTagName;
    this.listTarget.appendChild(newTagElement);

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

    // Remove HTML element from the list
    event.srcElement.parentElement.parentElement.remove();
  }

  filterInput(event) {
    // clear error class if key is not enter
    if (event.key !== "Enter") {
      this.newTagTarget.classList.remove("tag-error");
    }

    // Strip comma from tag name
    if (event.key === ",") {
      event.srcElement.value = event.srcElement.value.replace(",", "");
    }
  }
}
