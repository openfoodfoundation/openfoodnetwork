/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import stripe_cards_controller from "../../../app/webpacker/controllers/stripe_cards_controller";

describe("StripeCardsController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("stripe-cards", stripe_cards_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `<div data-controller="stripe-cards">
       <select data-action="change->stripe-cards#onSelectCard" id="select">
        <option value="">Blank</option>
        <option value="1">Card #1</option>
        <option value="2">Card #2</option>
       </select>
       <div data-stripe-cards-target="stripeelements" id="stripeelements" >
        <input type="hidden" id="input_1">
       </div>
      </div>`;
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
      expect(document.getElementById("input_1").disabled).toBe(true);

      select.value = "2";
      select.dispatchEvent(new Event("change"));
      expect(document.getElementById("stripeelements").style.display).toBe(
        "none"
      );
      expect(document.getElementById("input_1").disabled).toBe(true);

      select.value = "";
      select.dispatchEvent(new Event("change"));
      expect(document.getElementById("stripeelements").style.display).toBe(
        "block"
      );
      expect(document.getElementById("input_1").disabled).toBe(false);
    });
  });
});
