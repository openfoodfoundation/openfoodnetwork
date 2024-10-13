import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['form'];

  connect() {
    this.formTarget.addEventListener('submit', this.turboSubmit);
  }

  disconnect() {
    this.formTarget.removeEventListener('submit', this.turboSubmit);
  }

  turboSubmit(e) {
    e.preventDefault();
    const form = e.target;
    const url = new URL(form.action);
    const formData = new FormData(form);
    const params = new URLSearchParams(formData).toString();
    
    // Manually visit the new URL with the search params
    // inorder to preserve params
    Turbo.visit(`${url.pathname}?${params}`, { action: 'replace' });
  }
}
