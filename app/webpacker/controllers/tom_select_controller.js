import { Controller } from "stimulus";
import TomSelect from "tom-select/dist/esm/tom-select.complete";
import showHttpError from "../../webpacker/js/services/show_http_error";

export default class extends Controller {
  static values = {
    options: Object,
    placeholder: String,
    remoteUrl: String,
  };

  connect(options = {}) {
    let tomSelectOptions = {
      maxItems: 1,
      maxOptions: null,
      plugins: ["dropdown_input"],
      allowEmptyOption: true, // Show blank option (option with empty value)
      placeholder: this.placeholderValue || this.#emptyOption(),
      onItemAdd: function () {
        this.setTextboxValue("");
      },
      ...this.optionsValue,
      ...options,
    };

    if (this.remoteUrlValue) {
      this.#addRemoteOptions(tomSelectOptions);
    }

    this.control = new TomSelect(this.element, tomSelectOptions);
  }

  disconnect() {
    if (this.control) this.control.destroy();
  }

  // private

  #emptyOption() {
    const optionsArray = [...this.element.options];
    return optionsArray.find((option) => [null, ""].includes(option.value))?.text;
  }

  #buildUrl(query, page = 1) {
    const url = new URL(this.remoteUrlValue, window.location.origin);
    url.searchParams.set("q", query);
    url.searchParams.set("page", page);
    return url.toString();
  }

  #fetchOptions(query, callback) {
    const url = this.control.getUrl(query);

    fetch(url)
      .then((response) => {
        if (!response.ok) {
          showHttpError(response.status);
          throw response;
        }
        return response.json();
      })
      .then((json) => {
        /**
         * Expected API shape:
         * {
         *   results: [{ value, label }],
         *   pagination: { more: boolean }
         * }
         */
        if (json.pagination?.more) {
          const currentUrl = new URL(url);
          const currentPage = parseInt(currentUrl.searchParams.get("page") || "1");
          const nextUrl = this.#buildUrl(query, currentPage + 1);
          this.control.setNextUrl(query, nextUrl);
        }

        callback(json.results || []);
      })
      .catch((error) => {
        callback();
        console.error(error);
      });
  }

  #addRemoteOptions(options) {
    this.openedByClick = false;

    options.firstUrl = (query) => {
      return this.#buildUrl(query, 1);
    };

    options.load = this.#fetchOptions.bind(this);

    options.onFocus = function () {
      this.control.load("", () => {});
    }.bind(this);

    options.onDropdownOpen = function () {
      this.openedByClick = true;
    }.bind(this);

    options.onType = function () {
      this.openedByClick = false;
    }.bind(this);

    // As per TomSelect source code, no result feedback after API call is shown when this callback returns true.
    options.shouldLoad = function (query) {
      return this.openedByClick || query.length > 0;
    }.bind(this);

    options.valueField = "value";
    options.labelField = "label";
    options.searchField = "label";
  }
}
