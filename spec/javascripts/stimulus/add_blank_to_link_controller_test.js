/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import add_blank_to_link_controller from "../../../app/webpacker/controllers/add_blank_to_link_controller";

describe("AddBlankToLink", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("add-blank-to-link", add_blank_to_link_controller);
  });

  describe("#add-blank-to-link", () => {
    beforeEach(() => {
      document.body.innerHTML = `<div data-controller="add-blank-to-link"><a href="www.ofn.com">www.ofn.com</a></div>`;
    });

    it("adds target='_blank' to anchor tags", () => {
      const anchorTag = document.querySelector("a");
      expect(anchorTag.getAttribute("target")).toBe("_blank");
    });
  });
});
