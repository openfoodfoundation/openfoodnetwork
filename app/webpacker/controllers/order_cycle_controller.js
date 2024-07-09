import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['input', 'modalConfirm'];
  static values = { initVals: { type: Object, default: {} }, hasSchedule: { type: Boolean, default: false } };

  connect() {
    if(!this.hasScheduleValue) return;
    // Attach update callback method
    window.adminOrderCycleUpdateCallback = this.updateCallback.bind(this);
  }

  toggleSaveBtns() {
    if(!this.hasScheduleValue) return;

    // Check that datetime input value has a change
    const dirty = this.inputTargets.some(ele =>
      new Date(this.initValsValue[`${ele.name}`]).getTime() !== new Date(ele.value).getTime());

    // Toggle save bar action button
    if (dirty) {
      this.element.querySelector('#form-actions').style.display = 'none';
      this.element.querySelector('#modal-actions').style.display = 'unset';
    } else {
      this.element.querySelector('#form-actions').style.display = 'unset';
      this.element.querySelector('#modal-actions').style.display = 'none';
    }
  }

  updateModalConfirmButton(e) {
    if(!this.hasScheduleValue) return;
    // Display modal confirm button coresponding to save bar button clicked
    this.modalConfirmTargets.forEach(ele => {
      if (e.target.getAttribute('data-target') === ele.getAttribute('data-request')) {
        ele.style.display = 'unset';
      } else {
        ele.style.display = 'none';
      }
    });
  }

  updateCallback(data) {
    // Reset order values and update save bar buttons
    this.initValsValue = { 'order_cycle[orders_open_at]': data.orders_open_at, 'order_cycle[orders_close_at]': data.orders_close_at };
    this.toggleSaveBtns();
  }

  disconnect() {
    // remove attached update callback method
    delete window.adminOrderCycleUpdateCallback;
  }
}