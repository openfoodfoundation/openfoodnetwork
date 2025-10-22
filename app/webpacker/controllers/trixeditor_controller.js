import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    this.element.addEventListener("trix-change", this.#trixChange);
    this.#trixInitialize();
    this.element.addEventListener("trix-initialize", this.#trixInitialize);
  }

  disconnect() {
    this.element.removeEventListener("trix-change", this.#trixChange);
    this.element.removeEventListener("trix-initialize", this.#trixInitialize);
  }

  #trixChange = (event) => {
    // trigger a change event on the form that contains the Trix editor
    event.target.form.dispatchEvent(new Event("change", { bubbles: true }));
  };

  #trixActionInvoke = (event) => {
    if (event.actionName === "hr") {
      this.element.editor.insertAttachment(
        new Trix.Attachment({ content: "<hr />", contentType: "text/html" }),
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
  };

  #addHRButton = () => {
    const button_html = `
    <button type="button" class="trix-button trix-button--icon trix-button--icon-hr" data-trix-action="hr" title="Horizontal Rule" tabindex="-1">HR</button>`;
    const buttonGroup = this.element.toolbarElement.querySelector(
      ".trix-button-group--block-tools",
    );
    buttonGroup.insertAdjacentHTML("beforeend", button_html);
    buttonGroup.querySelector(".trix-button--icon-hr").addEventListener("click", (event) => {
      event.actionName = "hr";
      this.#trixActionInvoke(event);
    });
  };
}
