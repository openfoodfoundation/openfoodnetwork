/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import add_to_cart_controller from "controllers/add_to_cart_controller";

jest.mock("@hotwired/turbo", () => ({
  renderStreamMessage: jest.fn(),
}));

const flushPromises = () => new Promise(process.nextTick);

describe("AddToCartController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("add-to-cart", add_to_cart_controller);
    global.I18n = { t: (key, options) => `${options.quantity} in cart` };
  });

  beforeEach(async () => {
    jest.useFakeTimers({ doNotFake: ["nextTick", "queueMicrotask"] });
    global.fetch = jest.fn(() =>
      Promise.resolve({ text: () => Promise.resolve("<turbo-stream></turbo-stream>") }),
    );

    document.body.innerHTML = `
      <form action="http://example.com/cart/variants/1" data-controller="add-to-cart"
        data-action="submit->add-to-cart#submit"
        data-add-to-cart-variant-id-value="1"
        data-add-to-cart-quantity-value="0"
        data-add-to-cart-on-hand-value="3"
        data-add-to-cart-on-demand-value="false">
        <div data-add-to-cart-target="addGroup">
          <button type="button" id="add" data-action="click->add-to-cart#add">Add</button>
        </div>
        <div data-add-to-cart-target="controls" style="display: none">
          <button type="button" id="decrease" data-action="click->add-to-cart#decrement">－</button>
          <input type="number" name="quantity" value="0"
            data-add-to-cart-target="input" data-action="input->add-to-cart#inputChanged" />
          <button type="button" id="increase" data-action="click->add-to-cart#increment">＋</button>
        </div>
        <div data-add-to-cart-target="display"></div>
      </form>
    `;

    // Wait for Stimulus to connect the controller.
    await flushPromises();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  const input = () => document.querySelector("input[name=quantity]");

  describe("#add", () => {
    it("switches to the quantity controls", () => {
      document.getElementById("add").click();

      expect(input().value).toEqual("1");
      expect(document.querySelector("[data-add-to-cart-target=controls]").style.display).toEqual(
        "",
      );
      expect(document.querySelector("[data-add-to-cart-target=addGroup]").style.display).toEqual(
        "none",
      );
      expect(document.querySelector("[data-add-to-cart-target=display]").textContent).toEqual(
        "1 in cart",
      );
    });
  });

  describe("clamping", () => {
    it("caps the quantity at the stock on hand", () => {
      document.getElementById("add").click();
      for (let i = 0; i < 5; i++) document.getElementById("increase").click();

      expect(input().value).toEqual("3");
    });

    it("does not go below zero", () => {
      document.getElementById("add").click();
      document.getElementById("decrease").click();
      document.getElementById("decrease").click();

      expect(input().value).toEqual("0");
    });
  });

  describe("saving", () => {
    it("saves the quantity once after the debounce", () => {
      document.getElementById("add").click();
      document.getElementById("increase").click();

      expect(global.fetch).not.toHaveBeenCalled();

      jest.advanceTimersByTime(1000);

      expect(global.fetch).toHaveBeenCalledTimes(1);
      const [url, options] = global.fetch.mock.calls[0];
      expect(url).toEqual("http://example.com/cart/variants/1");
      expect(options.method).toEqual("PATCH");
      expect(JSON.parse(options.body)).toEqual({ quantity: 2 });
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
      document.getElementById("increase").click();
      jest.advanceTimersByTime(1000);
      document.getElementById("increase").click();
      jest.advanceTimersByTime(1000);
      expect(global.fetch).toHaveBeenCalledTimes(1);

      // Once the first request finishes, one follow-up request is sent
      resolveFetch({ text: () => Promise.resolve("") });
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
      expect(settled.mock.calls[0][0].detail).toEqual({ variantId: 1 });
    });
  });

  describe("group buy", () => {
    beforeEach(async () => {
      document.body.innerHTML = `
        <form action="http://example.com/cart/variants/1" data-controller="add-to-cart"
          data-action="submit->add-to-cart#submit"
          data-add-to-cart-variant-id-value="1"
          data-add-to-cart-quantity-value="0"
          data-add-to-cart-max-quantity-value="0"
          data-add-to-cart-group-buy-value="true"
          data-add-to-cart-on-hand-value="5"
          data-add-to-cart-on-demand-value="false">
          <div data-add-to-cart-target="addGroup">
            <button type="button" id="add" data-action="click->add-to-cart#addBulk">Add</button>
          </div>
          <div data-add-to-cart-target="controls" style="display: none">
            <button type="button" data-add-to-cart-target="bulkQuantity">0</button>
            <button type="button" data-add-to-cart-target="bulkMax">-</button>
          </div>
          <div data-add-to-cart-target="display">in cart</div>
          <div>
            <button type="button" id="decrease" data-action="click->add-to-cart#decrement">－</button>
            <input type="number" name="quantity" value="0"
              data-add-to-cart-target="input" data-action="input->add-to-cart#inputChanged" />
            <button type="button" id="increase" data-action="click->add-to-cart#increment">＋</button>
            <button type="button" id="decreaseMax" data-action="click->add-to-cart#decrementMax">－</button>
            <input type="number" name="max_quantity" value="0"
              data-add-to-cart-target="maxInput" data-action="input->add-to-cart#maxInputChanged" />
            <button type="button" id="increaseMax" data-action="click->add-to-cart#incrementMax">＋</button>
          </div>
        </form>
      `;

      await flushPromises();
    });

    const maxInput = () => document.querySelector("input[name=max_quantity]");

    it("adding raises the max quantity with the quantity", () => {
      document.getElementById("add").click();
      document.getElementById("increase").click();

      expect(input().value).toEqual("2");
      expect(maxInput().value).toEqual("2");
      expect(document.querySelector("[data-add-to-cart-target=bulkQuantity]").textContent).toEqual(
        "2",
      );
      expect(document.querySelector("[data-add-to-cart-target=bulkMax]").textContent).toEqual("2");
    });

    it("the max quantity can exceed the quantity but not fall below it", () => {
      document.getElementById("add").click();
      document.getElementById("increaseMax").click();
      document.getElementById("increaseMax").click();

      expect(input().value).toEqual("1");
      expect(maxInput().value).toEqual("3");

      document.getElementById("decreaseMax").click();
      document.getElementById("decreaseMax").click();
      document.getElementById("decreaseMax").click();

      expect(maxInput().value).toEqual("0");
      expect(input().value).toEqual("0");
    });

    it("saves both quantities", () => {
      document.getElementById("add").click();
      document.getElementById("increaseMax").click();

      jest.advanceTimersByTime(1000);

      expect(JSON.parse(global.fetch.mock.calls[0][1].body)).toEqual({
        quantity: 1,
        max_quantity: 2,
      });
    });
  });
});
