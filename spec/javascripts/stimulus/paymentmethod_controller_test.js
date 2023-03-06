/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import paymentmethod_controller from "../../../app/webpacker/controllers/paymentmethod_controller";

describe("PaymentmethodController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("paymentmethod", paymentmethod_controller);
  });

  describe("#selectPaymentMethod", () => {
    beforeEach(() => {
      document.body.innerHTML = `<div data-controller="paymentmethod">
         <input id="paymentmethod_1" data-action="click->paymentmethod#selectPaymentMethod" data-paymentmethod-id="1" data-paymentmethod-target="input" />
         <input id="paymentmethod_2" data-action="click->paymentmethod#selectPaymentMethod" data-paymentmethod-id="2" data-paymentmethod-target="input" checked="checked" />
         <input id="paymentmethod_3" data-action="click->paymentmethod#selectPaymentMethod" data-paymentmethod-id="3" data-paymentmethod-target="input"/>

         <div class="paymentmethod-container" id="paymentmethod1" data-paymentmethod-id="1">
          <input type="number" id="input1" />
          <select id="select1" >
            <option value="1">1</option>
          </select>
         </div>
         <div class="paymentmethod-container" id="paymentmethod2" data-paymentmethod-id="2">
          <input type="number" id="input2" />
          <select id="select2" >
            <option value="1">1</option>
          </select>
         </div>
         <div class="paymentmethod-container" id="paymentmethod3" data-paymentmethod-id="3">
          <input type="number" id="input3" />
          <select id="select3" >
            <option value="1">1</option>
          </select>
         </div>
       </div>`;
    });

    it("fill the right payment container", () => {
      const paymentMethod1 = document.getElementById("paymentmethod_1");
      const paymentMethod2 = document.getElementById("paymentmethod_2");
      const paymentMethod3 = document.getElementById("paymentmethod_3");

      const paymentMethod1Container = document.getElementById("paymentmethod1");
      const paymentMethod2Container = document.getElementById("paymentmethod2");
      const paymentMethod3Container = document.getElementById("paymentmethod3");

      expect(paymentMethod1Container.style.display).toBe("none");
      expect(paymentMethod2Container.style.display).toBe("block");
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

    it("handle well the add/remove 'disabled='disabled'' attribute on each input/select", () => {
      const paymentMethod1 = document.getElementById("paymentmethod_1");
      const paymentMethod2 = document.getElementById("paymentmethod_2");
      const paymentMethod3 = document.getElementById("paymentmethod_3");

      const input1 = document.getElementById("input1");
      const input2 = document.getElementById("input2");
      const input3 = document.getElementById("input3");
      const select1 = document.getElementById("select1");
      const select2 = document.getElementById("select2");
      const select3 = document.getElementById("select3");

      paymentMethod1.click();
      expect(input1.disabled).toBe(false);
      expect(select1.disabled).toBe(false);

      expect(input2.disabled).toBe(true);
      expect(select2.disabled).toBe(true);
      expect(input3.disabled).toBe(true);
      expect(select3.disabled).toBe(true);

      paymentMethod2.click();
      expect(input2.disabled).toBe(false);
      expect(select2.disabled).toBe(false);

      expect(input1.disabled).toBe(true);
      expect(select1.disabled).toBe(true);
      expect(input3.disabled).toBe(true);
      expect(select3.disabled).toBe(true);

      paymentMethod3.click();
      expect(input3.disabled).toBe(false);
      expect(select3.disabled).toBe(false);

      expect(input1.disabled).toBe(true);
      expect(select1.disabled).toBe(true);
      expect(input2.disabled).toBe(true);
      expect(select2.disabled).toBe(true);
    });
  });
});
