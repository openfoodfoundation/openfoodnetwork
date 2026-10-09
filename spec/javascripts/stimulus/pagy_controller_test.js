/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import Pagy from "js/pagy.mjs";
import pagy_controller from "../../../app/webpacker/controllers/pagy_controller";

jest.mock("js/pagy.mjs", () => ({ init: jest.fn() }));

describe("PagyController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("pagy", pagy_controller);
  });

  it("renders the page links within its element", async () => {
    document.body.innerHTML = `<div id="pagination" data-controller="pagy"></div>`;
    // Stimulus connects controllers asynchronously
    await Promise.resolve();

    expect(Pagy.init).toHaveBeenCalledWith(document.getElementById("pagination"));
  });
});
