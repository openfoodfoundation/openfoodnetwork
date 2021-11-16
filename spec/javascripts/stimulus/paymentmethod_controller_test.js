/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import paymentmethod_controller from "../../../app/webpacker/controllers/paymentmethod_controller";

describe("PaymentmethodController", () => {
  describe("#selectPaymentMethod", () => {
    beforeEach(() => {
      document.body.innerHTML = `<div data-controller="paymentmethod">
         <span id="paymentmethod_1" data-action="click->paymentmethod#selectPaymentMethod" data-paymentmethod-id="paymentmethod1" />
         <span id="paymentmethod_2" data-action="click->paymentmethod#selectPaymentMethod" data-paymentmethod-id="paymentmethod2" />
         <span id="paymentmethod_3" data-action="click->paymentmethod#selectPaymentMethod" data-paymentmethod-id="paymentmethod3" />
         
         <div class="paymentmethod-container" id="paymentmethod1"></div>
         <div class="paymentmethod-container" id="paymentmethod2"></div>
         <div class="paymentmethod-container" id="paymentmethod3"></div>
       </div>`;

      const application = Application.start();
      application.register("paymentmethod", paymentmethod_controller);
    });

    it("fill the right payment description", () => {
      const paymentMethod1 = document.getElementById("paymentmethod_1");
      const paymentMethod2 = document.getElementById("paymentmethod_2");
      const paymentMethod3 = document.getElementById("paymentmethod_3");

      const paymentMethod1Container = document.getElementById("paymentmethod1");
      const paymentMethod2Container = document.getElementById("paymentmethod2");
      const paymentMethod3Container = document.getElementById("paymentmethod3");

      expect(paymentMethod1Container.style.display).toBe("none");
      expect(paymentMethod2Container.style.display).toBe("none");
      expect(paymentMethod3Container.style.display).toBe("none");

      paymentMethod1.click();
      expect(paymentMethod1Container.style.display).toBe("block");
      expect(paymentMethod2Container.style.display).toBe("none");
      expect(paymentMethod3Container.style.display).toBe("none");

      paymentMethod3.click();
      expect(paymentMethod1Container.style.display).toBe("none");
      expect(paymentMethod2Container.style.display).toBe("none");
      expect(paymentMethod3Container.style.display).toBe("block");
    });
  });
});
