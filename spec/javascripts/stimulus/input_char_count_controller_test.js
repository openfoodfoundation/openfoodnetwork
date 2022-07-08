/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import input_char_count_controller from "../../../app/webpacker/controllers/input_char_count_controller";

describe("InputCharCountController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("input-char-count", input_char_count_controller);
  });

  describe("default behavior", () => {
    beforeEach(() => {
      document.body.innerHTML = `<div data-controller="input-char-count">
        <input type='text' maxLength='280' id='input' data-input-char-count-target='input' value='Hello' />
        <span id='count' data-input-char-count-target='count'></span>
      </div>`;
    });

    it("handle the content", () => {
      const input = document.getElementById("input");
      const count = document.getElementById("count");
      // Default value
      expect(count.textContent).toBe("5/280");

      input.value = "Hello world";
      input.dispatchEvent(new Event("keyup"));

      expect(count.textContent).toBe("11/280");
    });
  });
});
