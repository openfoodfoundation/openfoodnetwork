import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    this.element.addEventListener('turbo:submit-end', this.closeModal.bind(this));
    document.addEventListener('modal-open', this.modalOpen.bind(this));
    document.addEventListener('modal-close', this.modalClose.bind(this));
  }

  disconnect() {
    this.element.removeEventListener('turbo:submit-end', this.closeModal);
    document.removeEventListener('modal-open', this.modalOpen);
    document.removeEventListener('modal-close', this.modalClose);
  }

  printInvoices(e) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
    const data = { bulk_ids: this.getSelectedIds() };

    fetch(e.target.getAttribute('data-url'), {
      method: "POST",
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify(data),
    })
      .then((response) => response.text())
      .then((html) => {
        Turbo.renderStreamMessage(html);
      })
      .catch((error) => console.error(error));
  }

  closeModal(event) {
    if (event.detail.success) {
      this.element.querySelector("button[type='button']").click();
    }
  }

  getSelectedIds() {
    const checkboxes = document.querySelectorAll(
      "table input[name='bulk_ids[]']:checked"
    );
    return Array.from(checkboxes).map((checkbox) => checkbox.value);
  }

  modalOpen(e) {
    if (!e.target.contains(this.element)) return;

    this.getSelectedIds().forEach((value) => {
      const input = Object.assign(document.createElement("input"), {
        type: "hidden",
        name: "bulk_ids[]",
        value,
      });
      this.element.appendChild(input);
    });

    this.element.querySelectorAll("input[type='checkbox']").forEach(element => {
      element.checked = true;
    });
  }

  modalClose(e) {
    if (!e.target.contains(this.element)) return;

    this.element.querySelectorAll("input[name='bulk_ids[]']").forEach(ele => ele.remove());
  }
}
