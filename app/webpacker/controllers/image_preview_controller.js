import { Controller } from "stimulus";

// Previews a newly selected image file without uploading it. The file is only sent to the
// server when the surrounding form is saved.
export default class ImagePreviewController extends Controller {
  static targets = ["preview", "filename"];

  disconnect() {
    this.releaseObjectUrl();
  }

  update(event) {
    const file = event.target.files[0];
    if (!file) {
      return;
    }

    this.releaseObjectUrl();
    this.objectUrl = URL.createObjectURL(file);

    this.previewTarget.src = this.objectUrl;
    this.filenameTarget.textContent = file.name;
  }

  releaseObjectUrl() {
    if (!this.objectUrl) {
      return;
    }

    URL.revokeObjectURL(this.objectUrl);
    this.objectUrl = null;
  }
}
