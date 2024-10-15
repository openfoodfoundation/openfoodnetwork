import consumer from './consumer'

consumer.subscriptions.create("SessionChannel", {
  received(data) {
    if (!data.selector) return;

    document.querySelector(data.selector).innerHTML = data.html;
  }
});
