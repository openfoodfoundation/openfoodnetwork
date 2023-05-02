import { Controller } from "stimulus";
import consumer from "../channels/consumer";
import CableReady from "cable_ready";

export default class extends Controller {
  static values = { id: String };

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "ScopedChannel", id: this.idValue },
      {
        received(data) {
          if (data.cableReady) CableReady.perform(data.operations);
        },
      }
    );
  }

  disconnect() {
    consumer.subscriptions.remove(this.subscription);
  }
}
