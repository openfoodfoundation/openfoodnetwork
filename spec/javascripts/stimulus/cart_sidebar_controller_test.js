/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import cart_sidebar_controller from "controllers/cart_sidebar_controller";

const flushPromises = () => new Promise(process.nextTick);

describe("CartSidebarController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("cart-sidebar", cart_sidebar_controller);
    global.I18n = {
      t: (key) => (key === "cart_updating" ? "Updating cart..." : "Edit cart"),
    };
  });

  beforeEach(async () => {
    document.body.innerHTML = `
      <div data-controller="cart-sidebar"
           data-action="cart:updating@window->cart-sidebar#cartUpdating cart:settled@window->cart-sidebar#cartSettled">
        <span id="icon" class="cart-span" data-cart-sidebar-target="icon">
          <a id="cart" data-action="click->cart-sidebar#toggle">
            <span id="counter" data-cart-sidebar-target="counter">0</span>
          </a>
        </span>
        <div id="sidebar" class="cart-sidebar" data-cart-sidebar-target="sidebar" data-item-count="2">
          <div class="background" data-action="click->cart-sidebar#close"></div>
          <div class="sidebar-footer">
            <a id="editCart" class="button" href="/cart">
              <span data-cart-sidebar-target="editCartLabel">Edit cart</span>
            </a>
            <a id="checkout" class="button" href="/checkout">Checkout</a>
          </div>
        </div>
      </div>
    `;

    // Wait for Stimulus to connect the controller.
    await flushPromises();
  });

  const sidebar = () => document.getElementById("sidebar");
  const dispatch = (name, variantId) =>
    window.dispatchEvent(new CustomEvent(name, { detail: { variantId } }));

  describe("toggling", () => {
    it("opens and closes the sidebar", async () => {
      document.getElementById("cart").click();
      // The open state is applied by Stimulus' value changed callback.
      await flushPromises();

      expect(sidebar().classList).toContain("shown");
      expect(document.body.style.overflow).toEqual("hidden");

      document.querySelector(".background").click();
      await flushPromises();

      expect(sidebar().classList).not.toContain("shown");
      expect(document.body.style.overflow).toEqual("");
    });
  });

  describe("connecting the sidebar", () => {
    it("updates the icon counters from the sidebar's item count", () => {
      expect(document.getElementById("counter").textContent).toEqual("2");
      expect(document.getElementById("icon").classList).not.toContain("dirty");
      expect(sidebar().getAttribute("aria-busy")).toEqual("false");
    });

    it("marks the icon of an empty cart", async () => {
      sidebar().dataset.itemCount = "0";
      // Re-connect the target by re-adding it to the DOM
      const wrapper = sidebar().parentElement;
      const detached = sidebar();
      detached.remove();
      wrapper.appendChild(detached);
      await flushPromises();

      expect(document.getElementById("counter").textContent).toEqual("0");
      expect(document.getElementById("icon").classList).toContain("dirty");
    });
  });

  describe("busy state", () => {
    it("shows while updates are pending and clears when all are settled", () => {
      dispatch("cart:updating", 1);
      dispatch("cart:updating", 2);

      expect(sidebar().getAttribute("aria-busy")).toEqual("true");
      expect(document.getElementById("editCart").hasAttribute("disabled")).toEqual(true);
      expect(document.getElementById("checkout").hasAttribute("disabled")).toEqual(true);
      expect(document.getElementById("editCart").textContent).toContain("Updating cart...");
      expect(document.getElementById("icon").classList).toContain("pure-dirty");

      // One of two variants settled: still busy
      dispatch("cart:settled", 1);
      expect(sidebar().getAttribute("aria-busy")).toEqual("true");

      dispatch("cart:settled", 2);
      expect(sidebar().getAttribute("aria-busy")).toEqual("false");
      expect(document.getElementById("editCart").hasAttribute("disabled")).toEqual(false);
      expect(document.getElementById("checkout").hasAttribute("disabled")).toEqual(false);
      expect(document.getElementById("editCart").textContent).toContain("Edit cart");
      expect(document.getElementById("icon").classList).not.toContain("pure-dirty");
    });

    it("keeps the busy state when the sidebar is replaced", async () => {
      dispatch("cart:updating", 1);

      // Simulate a Turbo Stream replacing the sidebar
      sidebar().outerHTML = `
        <div id="sidebar" class="cart-sidebar" data-cart-sidebar-target="sidebar" data-item-count="3">
          <div class="sidebar-footer">
            <a id="editCart" class="button" href="/cart">
              <span data-cart-sidebar-target="editCartLabel">Edit cart</span>
            </a>
          </div>
        </div>
      `;
      await flushPromises();

      expect(sidebar().getAttribute("aria-busy")).toEqual("true");
      expect(document.getElementById("counter").textContent).toEqual("3");

      dispatch("cart:settled", 1);
      expect(sidebar().getAttribute("aria-busy")).toEqual("false");
    });
  });
});
