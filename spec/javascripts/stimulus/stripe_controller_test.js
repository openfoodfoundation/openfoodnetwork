/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import stripe_controller from "../../../app/webpacker/controllers/stripe_controller";

describe("StripeController", () => {
  beforeEach(() => {
    document.body.innerHTML = `<div data-controller="stripe">
       <select data-action="change->stripe#onSelectCard" id="select">
        <option value="">Blank</option>
        <option value="1">Card #1</option>
        <option value="2">Card #2</option>
       </select>
       <div data-stripe-target="stripeelements" id="stripeelements" />
      </div>`;

    const application = Application.start();
    application.register("stripe", stripe_controller);
  });
  describe("#connect", () => {
    it("initialize with the right display state", () => {
      const select = document.getElementById("select");
      select.value = "";
      select.dispatchEvent(new Event("change"));
      expect(document.getElementById("stripeelements").style.display).toBe(
        "block"
      );
    });
  });
  describe("#selectCard", () => {
    it("fill the right payment container", () => {
      const select = document.getElementById("select");
      select.value = "1";
      select.dispatchEvent(new Event("change"));

      expect(document.getElementById("stripeelements").style.display).toBe(
        "none"
      );

      select.value = "2";
      select.dispatchEvent(new Event("change"));
      expect(document.getElementById("stripeelements").style.display).toBe(
        "none"
      );

      select.value = "";
      select.dispatchEvent(new Event("change"));
      expect(document.getElementById("stripeelements").style.display).toBe(
        "block"
      );
    });
  });
});
