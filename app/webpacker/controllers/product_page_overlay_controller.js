import { Controller } from "stimulus";

// Opens a product's page over the shop's product list instead of leaving the shop
// (feature: product-pages).
//
// The list stays in memory with its scroll position, loaded products and filters, so going
// back to it is as quick as closing the old product modal. The product's URL goes into the
// browser history: the back button closes the page and the URL can be shared. The links still
// point at the product page, so opening one in a new tab works as before.
//
// The shop's AngularJS cart stays in charge of the cart. See productPageOverlayCart.
//
// The shop's AngularJS watches the URL too. It can't make sense of a product's URL and would
// push a shop URL of its own, so the overlay keeps its history entries to itself.

// The overlay on this page. Listening from when this file loads, before AngularJS starts
// listening, lets it handle the history entries first.
let overlay = null;
window.addEventListener("popstate", (event) => overlay?.onPopState(event));

export default class extends Controller {
  static targets = ["dialog", "content"];

  connect() {
    overlay = this;
  }

  disconnect() {
    if (overlay === this) overlay = null;
    this.abortController?.abort();
  }

  async open(event) {
    // Leave new tabs and windows to the browser.
    if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
      return;
    }
    event.preventDefault();

    const url = event.currentTarget.href;
    if (!(await this.load(url))) return;

    this.changeHistory({ productPageOverlay: url }, url);
    this.show();
  }

  // Closing goes back in history, to the list's URL, which closes the page.
  close() {
    if (history.state?.productPageOverlay) {
      history.back();
    } else {
      this.hide();
    }
  }

  async onPopState(event) {
    const url = event.state?.productPageOverlay;
    if (!url && !this.dialogTarget.open) return; // the shop's own history

    event.stopImmediatePropagation();
    this.changeHistory(history.state, window.location.href, { replace: true });

    if (!url) {
      this.hide();
    } else if (await this.load(url)) {
      this.show();
    }
  }

  // private

  // Fetches the content of the product page. Anything unexpected, like an error page, is left
  // to the browser to show by going to the product page itself.
  async load(url) {
    this.abortController?.abort();
    this.abortController = new AbortController();

    const contentUrl = new URL(url, window.location.href);
    contentUrl.searchParams.set("overlay", "true");

    let content;
    try {
      const response = await fetch(contentUrl, {
        headers: { Accept: "text/html" },
        credentials: "same-origin",
        signal: this.abortController.signal,
      });
      const template = document.createElement("template");
      template.innerHTML = await response.text();
      content = response.ok && template.content.querySelector(".product-page-overlay-content");
    } catch (error) {
      if (error.name === "AbortError") return false;
    }

    if (!content) {
      window.location.href = url;
      return false;
    }

    this.contentTarget.replaceChildren(content);
    this.title = content.dataset.title;
    return true;
  }

  // AngularJS's $browser changes history for us and remembers the result, so it doesn't take
  // the change for one of its own. Replacing the current entry with itself only updates what it
  // remembers.
  changeHistory(state, url, { replace = false } = {}) {
    const browser = window.angular?.element(document.body).injector()?.get("$browser");

    if (browser) {
      // It compares URLs without an empty hash, like the shop's "/shop#".
      browser.url(url.replace(/#$/, ""), replace, state);
    } else if (!replace) {
      history.pushState(state, "", url);
    }
  }

  show() {
    const dialog = this.dialogTarget;

    if (!dialog.open) {
      this.listTitle = document.title;
      dialog.showModal();
    }
    dialog.setAttribute("aria-label", this.title);
    dialog.scrollTop = 0;
    document.title = this.title;
  }

  hide() {
    this.abortController?.abort();

    const dialog = this.dialogTarget;
    if (!dialog.open) return;

    dialog.close();
    document.title = this.listTitle;
    this.contentTarget.replaceChildren();
  }
}
