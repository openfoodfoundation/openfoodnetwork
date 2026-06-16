/**
 * @jest-environment jsdom
 * @jest-environment-options {"url": "http://www.example.com/"}
 */

import { Application } from "stimulus";
import add_to_cart_controller from "add_to_cart_component/add_to_cart_controller";

describe("AddToCartController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("add-to-cart", add_to_cart_controller);
  });

  let dispatchEventSpy;
  const htmlTemplate = (quantity = 0, onHand = 10) => `
      <div 
        data-controller="add-to-cart" 
        data-add-to-cart-variant-id-value="10"
        data-add-to-cart-variant-on-hand-value="${onHand}"
        data-add-to-cart-low-stock-display-value="true"
      >
        <div id="add_container" class="variant-quantity-inputs" data-add-to-cart-target="addButton">
          <button id="add" name="button" type="button" class="add-variant" data-action="add-to-cart#addEmpty">Add</button>
        </div>
        <div id="quantity_buttons" class="variant-quantity-inputs" data-add-to-cart-target="quantityButton" style="display: none;">
          <button id="minus" class="variant-quantity" data-action="add-to-cart#remove" type="button">
            - 
          </button>
          <input id="quantity" class="variant-quantity" data-add-to-cart-target="quantity" data-action="keyup->add-to-cart#manual" min="0" type="number" value="${quantity}">
          <button id="plus" class="variant-quantity" data-action="add-to-cart#add" data-add-to-cart-target="plusButton" type="button">
            + 
          </button>
        </div>
        <div id="remaining_stock" class="variant-remaining-stock" style="display: none;" data-add-to-cart-target="stock">
          Only ${onHand} left
        </div>
        <div id="item-in-cart" class="variant-quantity-display" data-add-to-cart-target="nbItemInCart">
          ${quantity} in cart
        </div>
      </div>`;

  beforeEach(() => {
    document.body.innerHTML = htmlTemplate();

    const mockedT = jest.fn();
    mockedT.mockImplementation((string, opts) => string + ", " + JSON.stringify(opts));

    global.I18n = { t: mockedT };

    dispatchEventSpy = jest.spyOn(window, "dispatchEvent");
  });

  afterAll(() => {
    delete global.I18n;
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

      expect(quantity_buttons.style.display).toBe("flex");
      expect(add_container.style.display).toBe("none");
      const quantity = document.getElementById("quantity");
      expect(quantity.value).toEqual("1");
    });

    it("shows one item in the cart", () => {
      const add_button = document.getElementById("add");
      const itemInCart = document.getElementById("item-in-cart");

      add_button.click();

      expect(itemInCart.style.visibility).toBe("visible");
      expect(itemInCart.textContent).toBe('js.shopfront.variant.quantity_in_cart, {"quantity":1}');
    });

    describe("when low stock is displayed", () => {
      beforeEach(() => {
        document.body.innerHTML = htmlTemplate(0, 2);
      });

      it("hides low stock", () => {
        const add_button = document.getElementById("add");
        const remaining_stock = document.getElementById("remaining_stock");

        expect(remaining_stock.style.display).toBe("block");

        add_button.click();

        expect(remaining_stock.style.display).toBe("none");
      });
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

    it("updates the number of item in the cart", () => {
      const plus_button = document.getElementById("plus");
      const itemInCart = document.getElementById("item-in-cart");
      const quantity = document.getElementById("quantity");
      quantity.value = 5;

      plus_button.click();

      expect(itemInCart.style.visibility).toBe("visible");
      expect(itemInCart.textContent).toBe('js.shopfront.variant.quantity_in_cart, {"quantity":6}');
    });

    describe("when quantity equal available stock", () => {
      beforeEach(() => {
        document.body.innerHTML = htmlTemplate(4, 5);
      });

      it("disables the add button", () => {
        const plus_button = document.getElementById("plus");

        plus_button.click();

        expect(plus_button.disabled).toBe(true);
      });
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

    it("updates the number of item in the cart", () => {
      const minus_button = document.getElementById("minus");
      const itemInCart = document.getElementById("item-in-cart");
      const quantity = document.getElementById("quantity");
      quantity.value = 5;

      minus_button.click();

      expect(itemInCart.style.visibility).toBe("visible");
      expect(itemInCart.textContent).toBe('js.shopfront.variant.quantity_in_cart, {"quantity":4}');
    });

    describe("when quantity becomes 0", () => {
      beforeEach(() => {
        document.body.innerHTML = htmlTemplate(1);
      });

      it("toggles to the add button", () => {
        const add_container = document.getElementById("add_container");
        const quantity_buttons = document.getElementById("quantity_buttons");
        const minus_button = document.getElementById("minus");

        expect(quantity_buttons.style.display).toBe("flex");
        expect(add_container.style.display).toBe("none");

        minus_button.click();

        expect(quantity_buttons.style.display).toBe("none");
        expect(add_container.style.display).toBe("block");
      });

      it("hides the number of item in cart", () => {
        const minus_button = document.getElementById("minus");
        const itemInCart = document.getElementById("item-in-cart");

        minus_button.click();

        expect(itemInCart.style.visibility).toBe("hidden");
        expect(itemInCart.textContent).toBe(
          'js.shopfront.variant.quantity_in_cart, {"quantity":0}'
        );
      });

      describe("when low stock", () => {
        beforeEach(() => {
          document.body.innerHTML = htmlTemplate(1, 2);
        });

        it("shows low stock", () => {
          const minus_button = document.getElementById("minus");
          const remaining_stock = document.getElementById("remaining_stock");

          expect(remaining_stock.style.display).toBe("none");

          minus_button.click();

          expect(remaining_stock.style.display).toBe("block");
        });
      });
    });

    describe("when quantity below available stock", () => {
      beforeEach(() => {
        document.body.innerHTML = htmlTemplate(5, 5);
      });

      it("enables the add button", () => {
        const minus_button = document.getElementById("minus");
        const plus_button = document.getElementById("plus");

        minus_button.click();

        expect(plus_button.disabled).toBe(false);
      });
    });
  });

  describe("quantity input", () => {
    beforeEach(() => {
      document.body.innerHTML = htmlTemplate(1);
    });

    it("update quantity in cart by the given number", () => {
      const quantity = document.getElementById("quantity");
      quantity.value = 3;
      quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "3" }));

      const lastCall = getLastMockCall();
      expect(lastCall.type).toEqual("updateCart");
      const detail = lastCall.detail;
      expect(detail.quantity).toEqual(3);
      expect(quantity.value).toEqual("3");
    });

    it("updates the number of item in the cart", () => {
      const itemInCart = document.getElementById("item-in-cart");

      const quantity = document.getElementById("quantity");
      quantity.value = 3;
      quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "3" }));

      expect(itemInCart.style.visibility).toBe("visible");
      expect(itemInCart.textContent).toBe('js.shopfront.variant.quantity_in_cart, {"quantity":3}');
    });

    it("does nothing if quantity is not a valid number", () => {
      const preTestCallsNb = dispatchEventSpy.mock.calls.length;

      const quantity = document.getElementById("quantity");
      quantity.value = "b";
      quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "b" }));

      expect(dispatchEventSpy).toHaveBeenCalledTimes(preTestCallsNb);
    });

    it("does nothing if quantity is negative", () => {
      const preTestCallsNb = dispatchEventSpy.mock.calls.length;

      const quantity = document.getElementById("quantity");
      quantity.value = "-2";
      quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "2" }));

      expect(dispatchEventSpy).toHaveBeenCalledTimes(preTestCallsNb);
    });

    describe("when quantity becomes 0", () => {
      it("toggles to the add button if quantity is 0", () => {
        const add_container = document.getElementById("add_container");
        const quantity_buttons = document.getElementById("quantity_buttons");

        const quantity = document.getElementById("quantity");
        quantity.value = "0";
        quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "0" }));

        const lastCall = getLastMockCall();
        expect(lastCall.type).toEqual("updateCart");
        expect(quantity_buttons.style.display).toBe("none");
        expect(add_container.style.display).toBe("block");
      });

      it("hides the number of item in cart", () => {
        const itemInCart = document.getElementById("item-in-cart");

        const quantity = document.getElementById("quantity");
        quantity.value = "0";
        quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "0" }));

        expect(itemInCart.style.visibility).toBe("hidden");
        expect(itemInCart.textContent).toBe(
          'js.shopfront.variant.quantity_in_cart, {"quantity":0}'
        );
      });

      describe("when low stock", () => {
        beforeEach(() => {
          document.body.innerHTML = htmlTemplate(1, 2);
        });

        it("shows low stock", () => {
          const remaining_stock = document.getElementById("remaining_stock");
          const quantity = document.getElementById("quantity");

          expect(remaining_stock.style.display).toBe("none");

          quantity.value = "0";
          quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "0" }));

          expect(remaining_stock.style.display).toBe("block");
        });
      });
    });

    describe("when quantity equal available stock", () => {
      beforeEach(() => {
        document.body.innerHTML = htmlTemplate(2, 5);
      });

      it("disables the add button", () => {
        const plus_button = document.getElementById("plus");

        quantity.value = "5";
        quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "5" }));

        expect(plus_button.disabled).toBe(true);
      });
    });

    describe("when quantity is more than available stock", () => {
      beforeEach(() => {
        document.body.innerHTML = htmlTemplate(2, 5);
      });

      it("sets quantity to availabe stock and disables the add button", () => {
        const plus_button = document.getElementById("plus");

        // TODO helper function
        quantity.value = "8";
        quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "8" }));

        expect(plus_button.disabled).toBe(true);
        expect(quantity.value).toBe("5");
      });
    });

    describe("when plus button disabled", () => {
      beforeEach(() => {
        document.body.innerHTML = htmlTemplate(5, 5);
      });

      it("enables plus button when quantity below available stock", () => {
        const plus_button = document.getElementById("plus");

        expect(plus_button.disabled).toBe(true);

        quantity.value = "2";
        quantity.dispatchEvent(new KeyboardEvent("keyup", { key: "2" }));

        expect(plus_button.disabled).toBe(false);
      });
    });
  });

  describe("connect", () => {
    describe("when quantity is positive", () => {
      beforeEach(() => {
        document.body.innerHTML = htmlTemplate(5);
      });

      it("displays the minus/plus button and quantity", () => {
        // TODO should be able to remove getElementById
        //const add_container = document.getElementById("add_container");
        //const quantity_buttons = document.getElementById("quantity_buttons");

        expect(quantity_buttons.style.display).toBe("flex");
        expect(add_container.style.display).toBe("none");
      });

      it("shows the number of items in the cart", () => {
        const itemInCart = document.getElementById("item-in-cart");

        expect(itemInCart.style.visibility).toBe("visible");
        expect(itemInCart.textContent.trim()).toBe("5 in cart");
      });
    });

    describe("when quantity is not positive", () => {
      beforeEach(() => {
        document.body.innerHTML = htmlTemplate(-2);
      });

      it("displays the add button", () => {
        const add_container = document.getElementById("add_container");
        const quantity_buttons = document.getElementById("quantity_buttons");

        expect(quantity_buttons.style.display).toBe("none");
        expect(add_container.style.display).toBe("");
      });
    });

    describe("when display low stock is enabled", () => {
      beforeEach(() => {
        document.body.innerHTML = htmlTemplate(0, 4);
      });

      it("doesn't show low stock warning", () => {
        const remaining_stock = document.getElementById("remaining_stock");

        expect(remaining_stock.style.display).toBe("none");
      });

      describe("when remaining stock below 4", () => {
        beforeEach(() => {
          document.body.innerHTML = htmlTemplate(0, 2);
        });

        it("shows low stock warning", () => {
          const remaining_stock = document.getElementById("remaining_stock");

          expect(remaining_stock.style.display).toBe("block");
        });
      });
    });

    describe("when quantity equal available stock", () => {
      beforeEach(() => {
        document.body.innerHTML = htmlTemplate(5, 5);
      });

      it("disables the plus button", () => {
        const plus_button = document.getElementById("plus");
        expect(plus_button.disabled).toBe(true);
      });
    });
  });

  const getLastMockCall = () => {
    return dispatchEventSpy.mock.calls.at(-1)[0];
  };
});
