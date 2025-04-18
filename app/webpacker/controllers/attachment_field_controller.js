import { Controller } from "stimulus";

export default class extends Controller {
  async remove() {
    const attachmentRemovalParameterKey = this.element.id; // e.g. 'remove_logo'
    const action = this.element.closest("form").action;
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
    const formData = new FormData();
    formData.append(`enterprise[${attachmentRemovalParameterKey}]`, "1")
    const response = await fetch(action, {
      method: 'PATCH',
      headers: {
        Accept: 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': csrfToken,
      },
      body: formData
    });
    const responseTurboStream = await response.text();
    Turbo.renderStreamMessage(responseTurboStream);
  }
}
