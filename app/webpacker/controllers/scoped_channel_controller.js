import { Controller } from "stimulus";
import consumer from "../channels/consumer";

export default class extends Controller {
  static values = { id: String };

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "ScopedChannel", id: this.idValue },
      {
        received(data) {
          if (!data.selector) return;

          document.querySelector(data.selector).innerHTML = data.html;
        },
      }
    );
  }

  disconnect() {
    consumer.subscriptions.remove(this.subscription);
  }
}
