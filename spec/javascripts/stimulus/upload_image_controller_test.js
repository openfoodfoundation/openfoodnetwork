/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import upload_image_controller from "../../../app/webpacker/controllers/upload_image_controller";

// Stimulus connects controllers asynchronously, so let the DOM mutations settle.
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

const selectFile = async (name = "new-image.jpg") => {
  const input = document.getElementById("attachment");
  const file = new File(["image-bytes"], name, { type: "image/jpeg" });

  Object.defineProperty(input, "files", { value: [file], configurable: true });
  input.dispatchEvent(new Event("change"));

  await flush();
};

const uploadedFormData = () => global.fetch.mock.calls[0][1].body;

describe("UploadImageController", () => {
  // jsdom's window.location cannot be redefined, so we observe the controller's own seam.
  let navigateTo;

  beforeAll(() => {
    const application = Application.start();
    application.register("upload-image", upload_image_controller);
  });

  beforeEach(async () => {
    global.Turbo = { renderStreamMessage: jest.fn() };
    navigateTo = jest
      .spyOn(upload_image_controller.prototype, "navigateTo")
      .mockImplementation(() => {});

    document.body.innerHTML = `
      <meta name="csrf-token" content="test-csrf-token">
      <div
        data-controller="upload-image"
        data-upload-image-url-value="/admin/products/7/images"
        data-upload-image-viewable-id-value="42"
      >
        <input
          id="attachment"
          type="file"
          name="image[attachment]"
          data-action="change->upload-image#upload"
        >
      </div>
    `;

    await flush();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe("when the upload succeeds", () => {
    beforeEach(() => {
      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ redirect_url: "/admin/products/7/images/3/edit" }),
        }),
      );
    });

    it("posts the file to the images endpoint", async () => {
      await selectFile();

      expect(global.fetch).toHaveBeenCalledTimes(1);

      const [url, options] = global.fetch.mock.calls[0];
      expect(url).toEqual("/admin/products/7/images");
      expect(options.method).toEqual("POST");
      expect(options.headers["X-CSRF-Token"]).toEqual("test-csrf-token");
    });

    it("sends the attachment, the viewable id and the redirect flag", async () => {
      await selectFile("courgettes.jpg");

      const body = uploadedFormData();
      expect(body.get("image[attachment]").name).toEqual("courgettes.jpg");
      expect(body.get("image[viewable_id]")).toEqual("42");
      expect(body.get("redirect_to_edit")).toEqual("true");
    });

    it("navigates to the image edit page", async () => {
      await selectFile();

      expect(navigateTo).toHaveBeenCalledWith("/admin/products/7/images/3/edit");
    });
  });

  describe("when the upload fails", () => {
    beforeEach(() => {
      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: false,
          text: () => Promise.resolve("<turbo-stream></turbo-stream>"),
        }),
      );
    });

    it("renders the returned turbo stream instead of navigating", async () => {
      await selectFile();

      expect(global.Turbo.renderStreamMessage).toHaveBeenCalledWith(
        "<turbo-stream></turbo-stream>",
      );
      expect(navigateTo).not.toHaveBeenCalled();
    });
  });

  describe("when no file was selected", () => {
    it("does not upload anything", async () => {
      global.fetch = jest.fn();
      const input = document.getElementById("attachment");
      Object.defineProperty(input, "files", { value: [], configurable: true });

      input.dispatchEvent(new Event("change"));
      await flush();

      expect(global.fetch).not.toHaveBeenCalled();
      expect(navigateTo).not.toHaveBeenCalled();
    });
  });
});
