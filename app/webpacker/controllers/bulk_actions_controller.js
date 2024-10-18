import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    document.addEventListener('modal-open', this.modalOpen.bind(this));
    document.addEventListener('modal-close', this.modalClose.bind(this));
  }

  disconnect() {
    document.removeEventListener('modal-open', this.modalOpen);
    document.removeEventListener('modal-close', this.modalClose);
  }

  appendParams(url, modal) {
    const search_url = new URL(url);
    const search_params = new URLSearchParams(search_url.search);
    this.getSelectedIds().forEach((value) => {
      search_params.append('bulk_ids[]', value);
    });

    const form = modal.querySelector("form[data-bulk-actions='extraParams']");
    if (form) {
      for (const pair of new FormData(form).entries()) {
        search_params.append(pair[0], pair[1]);
      }
    }
    
    search_url.search = search_params;
    
    return search_url;
  }

  getSelectedIds() {
    const checkboxes = document.querySelectorAll(
      "table input[name='bulk_ids[]']:checked"
    );
    return Array.from(checkboxes).map((checkbox) => checkbox.value);
  }

  modalOpen(e) {
    const modal = e.target;
    this.submitUrl = modal.querySelector("a[data-type='submit']").getAttribute('href');
    const href = this.appendParams(this.submitUrl, modal);
    modal.querySelector("a[data-type='submit']").setAttribute('href', href);
  }

  modalClose(e) {
    e.target.querySelector("a[data-type='submit']").setAttribute('href', this.submitUrl);
  }
}
