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
    // Set I18n translations on Trix.
    if(I18n.t("js.trix")) {
      // Calling 'Trix.config.lang = I18n.t("js.trix")' doesn't work due to read-only error, so set
      // translations one at a time.
      for (const [key, translation] of Object.entries(I18n.t("js.trix"))) {
        Trix.config.lang[key] = translation;
      }
    }

    // Add HR button to the Trix toolbar if it's not already there and the editor is present
    if (
      this.element.editor &&
      !this.element.toolbarElement.querySelector(".trix-button--icon-hr")
    ) {
      this.#addHRButton();
    }
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
}
