/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import add_to_cart_controller from "add_to_cart_component/add_to_cart_controller";
import showHttpError from "js/services/show_http_error";

jest.mock("@hotwired/turbo", () => ({
  renderStreamMessage: jest.fn(),
}));
jest.mock("js/services/show_http_error");

const flushPromises = () => new Promise(process.nextTick);

describe("AddToCartController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("add-to-cart", add_to_cart_controller);
    global.I18n = { t: (key, options) => `${options.quantity} in cart` };
  });

  const htmlTemplate = (quantity = 0, onHand = 3) => `
      <div
        data-controller="add-to-cart"
        data-add-to-cart-variant-id-value="10"
        data-add-to-cart-variant-on-hand-value="${onHand}"
        data-add-to-cart-low-stock-display-value="true"
        data-add-to-cart-url-value="http://example.com/cart/variants/10"
      >
        <div id="add_container" class="variant-quantity-inputs" data-add-to-cart-target="addButton">
          <button id="add" type="button" class="add-variant" data-action="add-to-cart#addEmpty">Add</button>
        </div>
        <div id="quantity_buttons" class="variant-quantity-inputs" data-add-to-cart-target="quantityButton" style="display: none;">
          <button id="minus" class="variant-quantity" data-action="add-to-cart#remove" type="button">-</button>
          <input id="quantity" class="variant-quantity" data-add-to-cart-target="quantity" data-action="keyup->add-to-cart#manual" min="0" type="number" value="${quantity}">
          <button id="plus" class="variant-quantity" data-action="add-to-cart#add" data-add-to-cart-target="plusButton" type="button">+</button>
        </div>
        <div id="remainingStock" class="variant-remaining-stock" style="display: none;" data-add-to-cart-target="stock">
          Only ${onHand} left
        </div>
        <div id="itemInCart" class="variant-quantity-display" data-add-to-cart-target="nbItemInCart">
          ${quantity} in cart
        </div>
      </div>`;

  beforeEach(async () => {
    jest.useFakeTimers({ doNotFake: ["nextTick", "queueMicrotask"] });
    global.fetch = jest.fn(() =>
      Promise.resolve({ ok: true, text: () => Promise.resolve("<turbo-stream></turbo-stream>") }),
    );

    document.body.innerHTML = htmlTemplate();

    // Wait for Stimulus to connect the controller.
    await flushPromises();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  const input = () => document.getElementById("quantity");

  describe("#addEmpty", () => {
    it("switches to the quantity controls", () => {
      document.getElementById("add").click();

      expect(input().value).toEqual("1");
      expect(document.getElementById("quantity_buttons").style.display).toEqual("flex");
      expect(document.getElementById("add_container").style.display).toEqual("none");
      expect(document.getElementById("itemInCart").textContent).toEqual("1 in cart");
      expect(document.getElementById("itemInCart").style.visibility).toEqual("visible");
    });
  });

  describe("clamping", () => {
    it("caps the quantity at the stock on hand and disables the plus button", () => {
      document.getElementById("add").click();
      for (let i = 0; i < 5; i++) document.getElementById("plus").click();

      expect(input().value).toEqual("3");
      expect(document.getElementById("plus").disabled).toEqual(true);
    });

    it("does not go below zero and switches back to the Add button", () => {
      document.getElementById("add").click();
      document.getElementById("minus").click();
      document.getElementById("minus").click();

      expect(input().value).toEqual("0");
      expect(document.getElementById("add_container").style.display).toEqual("block");
      expect(document.getElementById("quantity_buttons").style.display).toEqual("none");
    });

    it("shows the remaining stock when low and not in cart", () => {
      expect(document.getElementById("remainingStock").style.display).toEqual("block");

      document.getElementById("add").click();

      expect(document.getElementById("remainingStock").style.display).toEqual("none");
    });
  });

  describe("saving", () => {
    it("saves the quantity once after the debounce", () => {
      document.getElementById("add").click();
      document.getElementById("plus").click();

      expect(global.fetch).not.toHaveBeenCalled();

      jest.advanceTimersByTime(1000);

      expect(global.fetch).toHaveBeenCalledTimes(1);
      const [url, options] = global.fetch.mock.calls[0];
      expect(url).toEqual("http://example.com/cart/variants/10");
      expect(options.method).toEqual("PATCH");
      expect(JSON.parse(options.body)).toEqual({ quantity: 2 });
    });

    it("saves a manually entered quantity, clamped at the stock on hand", () => {
      document.getElementById("add").click();

      input().value = "9";
      input().dispatchEvent(new KeyboardEvent("keyup", { bubbles: true }));

      expect(input().value).toEqual("3");
      expect(document.getElementById("itemInCart").textContent).toEqual("3 in cart");

      jest.advanceTimersByTime(1000);

      expect(global.fetch).toHaveBeenCalledTimes(1);
      expect(JSON.parse(global.fetch.mock.calls[0][1].body)).toEqual({ quantity: 3 });
    });

    it("alerts the user when saving fails", async () => {
      global.fetch = jest.fn(() => Promise.resolve({ ok: false, status: 500 }));

      document.getElementById("add").click();
      jest.advanceTimersByTime(1000);
      await flushPromises();

      expect(showHttpError).toHaveBeenCalledWith(500);
    });

    it("coalesces changes made while a request is in flight", async () => {
      let resolveFetch;
      global.fetch = jest.fn(
        () =>
          new Promise((resolve) => {
            resolveFetch = resolve;
          }),
      );

      document.getElementById("add").click();
      jest.advanceTimersByTime(1000);
      expect(global.fetch).toHaveBeenCalledTimes(1);

      // Two changes while the first request is still running
      document.getElementById("plus").click();
      jest.advanceTimersByTime(1000);
      document.getElementById("plus").click();
      jest.advanceTimersByTime(1000);
      expect(global.fetch).toHaveBeenCalledTimes(1);

      // Once the first request finishes, one follow-up request is sent
      resolveFetch({ ok: true, text: () => Promise.resolve("") });
      await flushPromises();

      expect(global.fetch).toHaveBeenCalledTimes(2);
      expect(JSON.parse(global.fetch.mock.calls[1][1].body)).toEqual({ quantity: 3 });
    });

    it("dispatches cart:updating and cart:settled events", async () => {
      const updating = jest.fn();
      const settled = jest.fn();
      window.addEventListener("cart:updating", updating);
      window.addEventListener("cart:settled", settled);

      document.getElementById("add").click();
      expect(updating).toHaveBeenCalledTimes(1);
      expect(settled).not.toHaveBeenCalled();

      jest.advanceTimersByTime(1000);
      await flushPromises();

      expect(settled).toHaveBeenCalledTimes(1);
      expect(settled.mock.calls[0][0].detail).toEqual({ variantId: 10 });

      window.removeEventListener("cart:updating", updating);
      window.removeEventListener("cart:settled", settled);
    });
  });

  describe("on demand variants", () => {
    it("allows any quantity", async () => {
      document.body.innerHTML = htmlTemplate(0, "Infinity");
      await flushPromises();

      document.getElementById("add").click();
      for (let i = 0; i < 10; i++) document.getElementById("plus").click();

      expect(input().value).toEqual("11");
      expect(document.getElementById("plus").disabled).toEqual(false);
    });
  });

  describe("group buy", () => {
    const groupBuyTemplate = (quantity = 0, maxQuantity = 0, onHand = 10) => `
      <div
        data-controller="add-to-cart"
        data-add-to-cart-variant-id-value="10"
        data-add-to-cart-variant-on-hand-value="${onHand}"
        data-add-to-cart-low-stock-display-value="true"
        data-add-to-cart-group-buy-value="true"
        data-add-to-cart-url-value="http://example.com/cart/variants/10"
      >
        <div id="add_container" class="variant-quantity-inputs" data-add-to-cart-target="addButton">
          <button id="add" type="button" class="add-variant" data-action="add-to-cart#addEmpty">Add</button>
        </div>
        <div id="quantity_buttons" class="variant-quantity-labelled" data-add-to-cart-target="quantityButton" style="display: none;">
          <button id="minus" class="variant-quantity" data-action="add-to-cart#remove" type="button">-</button>
          <input id="quantity" class="variant-quantity" data-add-to-cart-target="quantity" data-action="keyup->add-to-cart#manual" min="0" type="number" value="${quantity}">
          <button id="plus" class="variant-quantity" data-action="add-to-cart#add" data-add-to-cart-target="plusButton" type="button">+</button>
        </div>
        <div id="max_quantity_buttons" class="variant-quantity-labelled" data-add-to-cart-target="maxQuantityButton" style="display: none;">
          <button id="maxMinus" class="variant-quantity" data-action="add-to-cart#removeMax" data-add-to-cart-target="maxMinusButton" type="button">-</button>
          <input id="maxQuantity" class="variant-quantity" data-add-to-cart-target="maxQuantity" data-action="keyup->add-to-cart#manualMax" min="0" type="number" value="${maxQuantity}">
          <button id="maxPlus" class="variant-quantity" data-action="add-to-cart#addMax" data-add-to-cart-target="maxPlusButton" type="button">+</button>
        </div>
      </div>`;

    const maxInput = () => document.getElementById("maxQuantity");

    beforeEach(async () => {
      document.body.innerHTML = groupBuyTemplate();
      await flushPromises();
    });

    it("sets both min and max to 1 on the first add", () => {
      document.getElementById("add").click();

      expect(input().value).toEqual("1");
      expect(maxInput().value).toEqual("1");
      expect(document.getElementById("max_quantity_buttons").style.display).toEqual("flex");
    });

    it("raises the max when the min is pushed above it", () => {
      document.getElementById("add").click();
      document.getElementById("plus").click();
      document.getElementById("plus").click();

      expect(input().value).toEqual("3");
      expect(maxInput().value).toEqual("3");
    });

    it("does not let the max go below the min", () => {
      document.getElementById("add").click();
      document.getElementById("plus").click(); // min = 2, max follows to 2

      document.getElementById("maxMinus").click();
      document.getElementById("maxMinus").click();

      expect(maxInput().value).toEqual("2");
      expect(document.getElementById("maxMinus").disabled).toEqual(true);
    });

    it("caps the max at the stock on hand", () => {
      document.getElementById("add").click();
      for (let i = 0; i < 15; i++) document.getElementById("maxPlus").click();

      expect(maxInput().value).toEqual("10");
      expect(document.getElementById("maxPlus").disabled).toEqual(true);
    });

    it("saves both quantity and max_quantity after the debounce", () => {
      document.getElementById("add").click();
      document.getElementById("maxPlus").click();

      jest.advanceTimersByTime(1000);

      expect(global.fetch).toHaveBeenCalledTimes(1);
      expect(JSON.parse(global.fetch.mock.calls[0][1].body)).toEqual({
        quantity: 1,
        max_quantity: 2,
      });
    });

    it("resets min and max and restores the Add button when min drops to 0", () => {
      document.getElementById("add").click();
      document.getElementById("plus").click();
      document.getElementById("minus").click();
      document.getElementById("minus").click();

      expect(input().value).toEqual("0");
      expect(maxInput().value).toEqual("0");
      expect(document.getElementById("add_container").style.display).toEqual("block");
      expect(document.getElementById("quantity_buttons").style.display).toEqual("none");
      expect(document.getElementById("max_quantity_buttons").style.display).toEqual("none");
    });
  });
});
