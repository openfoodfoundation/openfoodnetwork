/**
 * @jest-environment jsdom
 * @jest-environment-options {"url": "http://www.example.com/"}
 */

import { Application } from "stimulus";
import update_cart_controller from "controllers/update_cart_controller";

describe("UpdateCartController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("update-cart", update_cart_controller);
  });

  let dispatchEventSpy;

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="update-cart" data-update-cart-variant-id-value="10">
        <div id="add_container" class="variant-quantity-inputs" data-update-cart-target="addButton">
          <button id="add" name="button" type="button" class="add-variant" data-action="update-cart#addEmpty">Add</button>
        </div>
        <div id="quantity_buttons" class="variant-quantity-inputs" data-update-cart-target="quantityButton" style="display: none;">
          <button id="minus" class="variant-quantity" data-action="update-cart#remove" type="button">
            - 
          </button>
          <input id="quantity" class="variant-quantity" data-update-cart-target="quantity" data-action="keyup->update-cart#manual" min="0" type="number" value="0">
          <button id="plus" class="variant-quantity" data-action="update-cart#add" type="button">
            + 
          </button>
        </div>
        <div class="variant-remaining-stock" style="display: none;">
          Only 0 left
        </div>
        <div class="variant-quantity-display">
          0 in cart
        </div>
      </div>`;

    dispatchEventSpy = jest.spyOn(window, "dispatchEvent");
  });

  describe("#addEmpty", () => {
    it("add 1 item to the cart", () => {
      const add_button = document.getElementById("add");

      add_button.click();

      const lastCall = getLastMockCall();
      expect(lastCall.type).toEqual("updateCart");

      const detail = lastCall.detail;
      expect(detail.variant).toEqual({ id: 10 });
      expect(detail.quantity).toEqual(1);
    });

    it("toggles to minus/plus button and quantity input", () => {
      const add_button = document.getElementById("add");
      const add_container = document.getElementById("add_container");
      const quantity_buttons = document.getElementById("quantity_buttons");

      expect(quantity_buttons.style.display).toBe("none");

      add_button.click();

      expect(quantity_buttons.style.display).toBe("block");
      expect(add_container.style.display).toBe("none");
      const quantity = document.getElementById("quantity");
      expect(quantity.value).toEqual("1");
    });
  });

  describe("#add", () => {
    it("increase quantity by one", () => {
      const plus_button = document.getElementById("plus");
      const quantity = document.getElementById("quantity");
      quantity.value = 5;

      plus_button.click();

      const lastCall = getLastMockCall();
      expect(lastCall.type).toEqual("updateCart");

      const detail = lastCall.detail;
      expect(detail.quantity).toEqual(6);
      expect(quantity.value).toEqual("6");
    });
  });

  describe("#remove", () => {
    it("decrease quantity by one", () => {
      const minus_button = document.getElementById("minus");
      const quantity = document.getElementById("quantity");
      quantity.value = 5;

      minus_button.click();

      const lastCall = getLastMockCall();
      expect(lastCall.type).toEqual("updateCart");

      const detail = lastCall.detail;
      expect(detail.quantity).toEqual(4);
      expect(quantity.value).toEqual("4");
    });

    it("toggles to the add button when quantity reach 0", () => {
      const add_container = document.getElementById("add_container");
      const add_button = document.getElementById("add");
      const quantity_buttons = document.getElementById("quantity_buttons");
      const minus_button = document.getElementById("minus");

      // TODO should be able to remove this when we set button state base on quantity
      add_button.click();

      expect(quantity_buttons.style.display).toBe("block");
      expect(add_container.style.display).toBe("none");

      minus_button.click();

      expect(quantity_buttons.style.display).toBe("none");
      expect(add_container.style.display).toBe("block");
    });
  });

  describe("quantity input", () => {
    it("update quantity in cart by the given number", () => {
      // Set button state
      const add_button = document.getElementById("add");
      add_button.click();

      const quantity = document.getElementById("quantity");
      quantity.value = 3;
      quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "3" }));

      const lastCall = getLastMockCall();
      expect(lastCall.type).toEqual("updateCart");
      const detail = lastCall.detail;
      expect(detail.quantity).toEqual(3);
      expect(quantity.value).toEqual("3");
    });

    it("does nothing if quantity is not a valid number", () => {
      // Set button state
      const add_button = document.getElementById("add");
      add_button.click();

      const preTestCallsNb = dispatchEventSpy.mock.calls.length;

      const quantity = document.getElementById("quantity");
      quantity.value = "b";
      quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "b" }));

      expect(dispatchEventSpy).toHaveBeenCalledTimes(preTestCallsNb);
    });

    it("does nothing if quantity is negative", () => {
      // Set button state
      const add_button = document.getElementById("add");
      add_button.click();

      const preTestCallsNb = dispatchEventSpy.mock.calls.length;

      const quantity = document.getElementById("quantity");
      quantity.value = "-2";
      quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "2" }));

      expect(dispatchEventSpy).toHaveBeenCalledTimes(preTestCallsNb);
    });

    it("toggles to the add button if quantity is 0", () => {
      const add_container = document.getElementById("add_container");
      const quantity_buttons = document.getElementById("quantity_buttons");

      // Set button state
      const add_button = document.getElementById("add");
      add_button.click();

      const quantity = document.getElementById("quantity");
      quantity.value = "0";
      quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "0" }));

      const lastCall = getLastMockCall();
      expect(lastCall.type).toEqual("updateCart");
      expect(quantity_buttons.style.display).toBe("none");
      expect(add_container.style.display).toBe("block");
    });
  });

  describe("connect", () => {
    describe("when quantity is positive", () => {
      beforeEach(() => {
        document.body.innerHTML = `
          <div data-controller="update-cart" data-update-cart-variant-id-value="10">
            <div id="add_container" class="variant-quantity-inputs" data-update-cart-target="addButton">
              <button id="add" name="button" type="button" class="add-variant" data-action="update-cart#addEmpty">Add</button>
            </div>
            <div id="quantity_buttons" class="variant-quantity-inputs" data-update-cart-target="quantityButton" style="display: none;">
              <button id="minus" class="variant-quantity" data-action="update-cart#remove" type="button">
                - 
              </button>
              <input id="quantity" class="variant-quantity" data-update-cart-target="quantity" data-action="keyup->update-cart#manual" min="0" type="number" value="5">
              <button id="plus" class="variant-quantity" data-action="update-cart#add" type="button">
                + 
              </button>
            </div>
            <div class="variant-remaining-stock" style="display: none;">
              Only 0 left
            </div>
            <div class="variant-quantity-display">
              0 in cart
            </div>
          </div>`;
      });

      it("displays the minus/plus button and quantity", () => {
        const add_container = document.getElementById("add_container");
        const quantity_buttons = document.getElementById("quantity_buttons");

        expect(quantity_buttons.style.display).toBe("block");
        expect(add_container.style.display).toBe("none");
      });
    });

    describe("when quantity is not positive", () => {
      beforeEach(() => {
        document.body.innerHTML = `
          <div data-controller="update-cart" data-update-cart-variant-id-value="10">
            <div id="add_container" class="variant-quantity-inputs" data-update-cart-target="addButton">
              <button id="add" name="button" type="button" class="add-variant" data-action="update-cart#addEmpty">Add</button>
            </div>
            <div id="quantity_buttons" class="variant-quantity-inputs" data-update-cart-target="quantityButton" style="display: none;">
              <button id="minus" class="variant-quantity" data-action="update-cart#remove" type="button">
                - 
              </button>
              <input id="quantity" class="variant-quantity" data-update-cart-target="quantity" data-action="keyup->update-cart#manual" min="0" type="number" value="-2">
              <button id="plus" class="variant-quantity" data-action="update-cart#add" type="button">
                + 
              </button>
            </div>
            <div class="variant-remaining-stock" style="display: none;">
              Only 0 left
            </div>
            <div class="variant-quantity-display">
              0 in cart
            </div>
          </div>`;
      });

      it("displays the add button", () => {
        const add_container = document.getElementById("add_container");
        const quantity_buttons = document.getElementById("quantity_buttons");

        expect(quantity_buttons.style.display).toBe("none");
        expect(add_container.style.display).toBe("");
      });
    });
  });

  const getLastMockCall = () => {
    return dispatchEventSpy.mock.calls.at(-1)[0];
  };
});
