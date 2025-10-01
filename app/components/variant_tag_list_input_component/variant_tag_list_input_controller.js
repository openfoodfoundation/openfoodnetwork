import { Autocomplete } from "stimulus-autocomplete";

// Extend the stimulus-autocomplete controller, so we can add the ability to filter out existing
// tag
export default class extends Autocomplete {
  static targets = ["tags"];

  replaceResults(html) {
    const filteredHtml = this.#filterResults(html);
    super.replaceResults(filteredHtml);
  }

  //private

  #filterResults(html) {
    const existingTags = this.tagsTarget.value.split(",");
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
