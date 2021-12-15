/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import stripe_cards_controller from "../../../app/webpacker/controllers/stripe_cards_controller";

describe("StripeCardsController", () => {
  beforeEach(() => {
    document.body.innerHTML = `<div data-controller="stripe-cards">
       <select data-action="change->stripe-cards#onSelectCard" id="select">
        <option value="">Blank</option>
        <option value="1">Card #1</option>
        <option value="2">Card #2</option>
       </select>
       <div data-stripe-cards-target="stripeelements" id="stripeelements" />
      </div>`;

    const application = Application.start();
    application.register("stripe-cards", stripe_cards_controller);
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
