import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    window.addEventListener("trix-change", this.#trixChange);
    this.#trixInitialize();
    window.addEventListener("trix-initialize", this.#trixInitialize);
  }

  #trixChange = (event) => {
    // trigger a change event on the form that contains the Trix editor
    event.target.form.dispatchEvent(new Event("change", { bubbles: true }));
  };

  #trixActionInvoke = (event) => {
    if (event.actionName === "hr") {
      this.element.editor.insertAttachment(
        new Trix.Attachment({ content: "<hr />", contentType: "text/html" })
      );
    }
  };

  #trixInitialize = () => {
    // Add HR button to the Trix toolbar if it's not already there and the editor is present
    if (
      this.element.editor &&
      !this.element.toolbarElement.querySelector(".trix-button--icon-hr")
    ) {
      this.#addHRButton();
    }

    this.#setTranslations();
  };

  #addHRButton = () => {
    const button_html = `
    <button type="button" class="trix-button trix-button--icon trix-button--icon-hr" data-trix-action="hr" title="Horizontal Rule" tabindex="-1">HR</button>`;
    const buttonGroup = this.element.toolbarElement.querySelector(
      ".trix-button-group--block-tools"
    );
    buttonGroup.insertAdjacentHTML("beforeend", button_html);
    buttonGroup.querySelector(".trix-button--icon-hr").addEventListener("click", (event) => {
      event.actionName = "hr";
      this.#trixActionInvoke(event);
    });
  };

  #setTranslation(selector, attribute, value) {
    let element = this.element.parentElement.querySelector(selector);
    if(element && element.hasAttribute(attribute)) {
      element.setAttribute(attribute, value);
    }
  }

  #setTranslations() {
    if(I18n.t("js.trix")) {
      // Calling 'Trix.config.lang = I18n.t("js.trix")' doesn't work due to read-only error, so set
      // translations one at a time.
      for (const [key, translation] of Object.entries(I18n.t("js.trix"))) {

        // Set all translations (only works in Firefox for some reason)
        Trix.config.lang[key] = translation;

        // Set toolbar translations (Chrome)
        this.#setTranslation(
          `[data-trix-action="${this.#attributeOrActionForTranslationKey(key)}"]`,
          "title",
          translation
        );
        this.#setTranslation(
          `[data-trix-attribute="${this.#attributeOrActionForTranslationKey(key)}"]`,
          "title",
          translation
        );
      }

      // Set translations for link dialog (Chrome)
      this.#setTranslation(`[data-trix-dialog="href"] input`,
                                  "aria-label", I18n.t("js.trix.url"));
      this.#setTranslation(`[data-trix-dialog="href"] input`,
                                  "placeholder", I18n.t("js.trix.urlPlaceholder"));
      this.#setTranslation('.trix-dialog--link input[data-trix-method="setAttribute"]',
                                  "value", I18n.t("js.trix.link"));
      this.#setTranslation('.trix-dialog--link input[data-trix-method="removeAttribute"]',
                                  "value", I18n.t("js.trix.unlink"));
    }
  }

  #attributeOrActionForTranslationKey(key) {
    let mapping = {
      "bullets": "bullet",
      "link": "href",
      "numbers": "number",
      "indent": "increaseNestingLevel",
      "outdent": "decreaseNestingLevel"
    }[key];

    return mapping || key;
  }
}
