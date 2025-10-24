import { Autocomplete } from "stimulus-autocomplete";

// Extend the stimulus-autocomplete controller, so we can load tag with existing rules
// The autocomplete functionality is only loaded if the url value is set
// For more informatioon on "stimulus-autocomplete", see:
//    https://github.com/afcapel/stimulus-autocomplete/tree/main
//
export default class extends Autocomplete {
  static targets = ["tagList", "input", "template", "list"];
  static values = { onlyOne: Boolean };

  connect() {
    // Don't start autocomplete controller if we don't have an url
    if (this.urlValue.length == 0) return;

    super.connect();
  }

  addTag(event) {
    const newTagName = this.inputTarget.value.trim().replaceAll(" ", "-");
    if (newTagName.length == 0) {
      return;
    }

    // Check if tag already exist
    const tags = this.tagListTarget.value.split(",");
    const index = tags.indexOf(newTagName);
    if (index != -1) {
      // highlight the value in red
      this.inputTarget.classList.add("tag-error");
      return;
    }

    // add to tagList
    if (this.tagListTarget.value == "") {
      this.tagListTarget.value = newTagName;
    } else {
      this.tagListTarget.value = this.tagListTarget.value.concat(`,${newTagName}`);
    }
    // manualy dispatch an Input event so the change can get picked up by other controllers
    this.tagListTarget.dispatchEvent(new InputEvent("input"));

    // Create new li component with value
    const newTagElement = this.templateTarget.content.cloneNode(true);
    const spanElement = newTagElement.querySelector("span");
    spanElement.innerText = newTagName;
    this.listTarget.appendChild(newTagElement);

    // Clear new tag value
    this.inputTarget.value = "";

    // hide tag input if limited to one tag
    if (this.tagListTarget.value.split(",").length == 1 && this.onlyOneValue == true) {
      this.inputTarget.style.display = "none";
    }
  }

  keyboardAddTag(event) {
    // prevent hotkey form submitting the form (default action for "enter" key)
    if (event) {
      event.preventDefault();
    }

    this.addTag();
  }

  removeTag(event) {
    // Text to remove
    const tagName = event.srcElement.previousElementSibling.textContent;

    // Remove tag from list
    const tags = this.tagListTarget.value.split(",");
    this.tagListTarget.value = tags.filter((tag) => tag != tagName).join(",");

    // manualy dispatch an Input event so the change gets picked up by the bulk form controller
    this.tagListTarget.dispatchEvent(new InputEvent("input"));

    // Remove HTML element from the list
    event.srcElement.parentElement.parentElement.remove();

    // Make sure the tag input is displayed
    if (this.tagListTarget.value.length == 0) {
      this.inputTarget.style.display = "block";
    }
  }

  filterInput(event) {
    // clear error class if key is not enter
    if (event.key !== "Enter") {
      this.inputTarget.classList.remove("tag-error");
    }

    // Strip comma from tag name
    if (event.key === ",") {
      event.srcElement.value = event.srcElement.value.replace(",", "");
    }
  }

  // Add tag if we don't have an autocomplete list open
  onBlur() {
    // check if we have any autocomplete results
    if (this.resultsTarget.childElementCount == 0) this.addTag();
  }

  // Override original to add tag filtering
  replaceResults(html) {
    const filteredHtml = this.#filterResults(html);

    // Don't show result if we don't have anything to show
    if (filteredHtml.length == 0) return;

    super.replaceResults(filteredHtml);
  }

  // Override original to all empty query, which will return all existing tags
  onInputChange = () => {
    if (this.urlValue.length == 0) return;

    if (this.hasHiddenTarget) this.hiddenTarget.value = "";

    const query = this.inputTarget.value.trim();
    if (query.length >= this.minLengthValue) {
      this.fetchResults(query);
    } else {
      this.hideAndRemoveOptions();
    }
  };

  //private

  #filterResults(html) {
    const existingTags = this.tagListTarget.value.split(",");
    // Parse the HTML
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, "text/html");
    const lis = doc.getElementsByTagName("li");
    // Filter
    let filteredHtml = "";
    for (let li of lis) {
      if (!existingTags.includes(li.dataset.autocompleteValue)) {
        filteredHtml += li.outerHTML;
      }
    }

    return filteredHtml;
  }
}
