/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import image_preview_controller from "controllers/image_preview_controller";

// jsdom implements neither of these, and we need to observe the revoking.
const mockObjectUrls = () => {
  let created = 0;
  global.URL.createObjectURL = jest.fn(() => `blob:mock/${created++}`);
  global.URL.revokeObjectURL = jest.fn();
};

// Stimulus connects controllers asynchronously, so let the DOM mutations settle.
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

const selectFile = async (name) => {
  const input = document.getElementById("attachment");
  const file = new File(["image-bytes"], name, { type: "image/jpeg" });

  Object.defineProperty(input, "files", { value: [file], configurable: true });
  input.dispatchEvent(new Event("change"));

  await flush();
};

describe("ImagePreviewController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("image-preview", image_preview_controller);
  });

  beforeEach(async () => {
    // Tear the previous test's markup down first: disconnecting its controller revokes a url,
    // which would otherwise land on the fresh mock below.
    document.body.innerHTML = "";
    await flush();

    mockObjectUrls();

    document.body.innerHTML = `
      <div id="wrapper" data-controller="image-preview">
        <img
          id="preview"
          src="/existing-image.png"
          data-image-preview-target="preview"
        >
        <span id="filename" data-image-preview-target="filename">existing-image.png</span>
        <input
          id="attachment"
          type="file"
          data-action="change->image-preview#update"
        >
      </div>
    `;

    await flush();
  });

  describe("update", () => {
    it("previews the selected file and shows its name", async () => {
      await selectFile("new-image.jpg");

      expect(document.getElementById("preview").src).toContain("blob:mock/0");
      expect(document.getElementById("filename").textContent).toEqual("new-image.jpg");
    });

    it("does not upload the file", async () => {
      global.fetch = jest.fn();

      await selectFile("new-image.jpg");

      expect(global.fetch).not.toHaveBeenCalled();
    });

    it("leaves the preview alone when no file was selected", async () => {
      const input = document.getElementById("attachment");
      Object.defineProperty(input, "files", { value: [], configurable: true });

      input.dispatchEvent(new Event("change"));
      await flush();

      expect(document.getElementById("preview").src).toContain("/existing-image.png");
      expect(document.getElementById("filename").textContent).toEqual("existing-image.png");
      expect(global.URL.createObjectURL).not.toHaveBeenCalled();
    });

    it("releases the previous preview url when another file is selected", async () => {
      await selectFile("first.jpg");
      await selectFile("second.jpg");

      expect(global.URL.revokeObjectURL).toHaveBeenCalledWith("blob:mock/0");
      expect(document.getElementById("preview").src).toContain("blob:mock/1");
      expect(document.getElementById("filename").textContent).toEqual("second.jpg");
    });
  });

  describe("disconnect", () => {
    it("releases the preview url", async () => {
      await selectFile("new-image.jpg");
      expect(global.URL.revokeObjectURL).not.toHaveBeenCalled();

      document.getElementById("wrapper").remove();
      await flush();

      expect(global.URL.revokeObjectURL).toHaveBeenCalledWith("blob:mock/0");
    });

    it("does nothing when no file was ever selected", async () => {
      document.getElementById("wrapper").remove();
      await flush();

      expect(global.URL.revokeObjectURL).not.toHaveBeenCalled();
    });
  });
});
