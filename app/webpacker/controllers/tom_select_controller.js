import { Controller } from "stimulus";
import TomSelect from "tom-select/dist/esm/tom-select.complete";

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

  #addRemoteOptions(options) {
    // --- Pagination & request state ---
    this.page = 1;
    this.hasMore = true;
    this.loading = false;
    this.lastQuery = "";
    this.scrollAttached = false;

    const buildUrl = (query) => {
      const url = new URL(this.remoteUrlValue, window.location.origin);
      url.searchParams.set("q", query);
      url.searchParams.set("page", this.page);
      return url;
    };

    /**
     * Shared remote fetch handler.
     * Owns:
     * - request lifecycle
     * - pagination state
     * - loading UI when appending
     */
    const fetchOptions = ({ query, append = false, callback }) => {
      if (this.loading || !this.hasMore) {
        callback?.();
        return;
      }

      this.loading = true;

      const dropdown = this.control?.dropdown_content;
      const previousScrollTop = dropdown?.scrollTop;
      let loader;

      /**
       * When appending (infinite scroll), TomSelect does NOT
       * manage loading UI automatically — we must do it manually.
       */
      if (append && dropdown) {
        loader = this.control.render("loading");
        dropdown.appendChild(loader);
        this.control.wrapper.classList.add(this.control.settings.loadingClass);
      }

      fetch(buildUrl(query))
        .then((response) => response.json())
        .then((json) => {
          /**
           * Expected API shape:
           * {
           *   results: [{ value, label }],
           *   pagination: { more: boolean }
           * }
           */
          this.hasMore = Boolean(json.pagination?.more);
          this.page += 1;

          const results = json.results || [];

          if (append && dropdown) {
            this.control.addOptions(results);
            this.control.refreshOptions(false);
            /**
             * Preserve scroll position so newly appended
             * options don’t cause visual jumping.
             */
            requestAnimationFrame(() => {
              dropdown.scrollTop = previousScrollTop;
            });
          } else {
            callback?.(results);
          }
        })
        .catch(() => {
          callback?.();
        })
        .finally(() => {
          this.loading = false;

          if (append && loader) {
            this.control.wrapper.classList.remove(this.control.settings.loadingClass);
            loader.remove();
          }
        });
    };

    options.load = function (query, callback) {
      fetchOptions({ query, callback });
    }.bind(this);

    options.onType = function (query) {
      if (query === this.lastQuery) return;

      this.lastQuery = query;
      this.page = 1;
      this.hasMore = true;
    }.bind(this);

    options.onDropdownOpen = function () {
      if (this.scrollAttached) return;
      this.scrollAttached = true;

      const dropdown = this.control.dropdown_content;

      dropdown.addEventListener(
        "scroll",
        function () {
          const nearBottom =
            dropdown.scrollTop + dropdown.clientHeight >= dropdown.scrollHeight - 20;

          if (nearBottom) {
            this.#fetchNextPage();
          }
        }.bind(this),
      );
    }.bind(this);

    options.onFocus = function () {
      if (this.loading) return;

      this.lastQuery = "";
      this.control.load("", () => {});
    }.bind(this);

    options.valueField = "value";
    options.labelField = "label";
    options.searchField = "label";

    this._fetchOptions = fetchOptions;
  }

  #fetchNextPage() {
    if (this.loading || !this.hasMore) return;

    this._fetchOptions({
      query: this.lastQuery,
      append: true,
    });
  }
}
