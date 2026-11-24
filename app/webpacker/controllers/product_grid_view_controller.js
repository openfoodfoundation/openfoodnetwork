import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["loading", "products"];
  static values = {
    maxWidth: { type: Number, default: 500 },
    url: String,
  };

  updateProducts(ev) {
    const orderCycleId = ev.detail.orderCycleId;
    // Updating the turbo-frame source will reload the frame
    this.element.src = this.#addIsMobileTo(`/order_cycles/${orderCycleId}/products`).toString();
  }

  // This triggered when the DOM Content is loaded, it adds "is_mobile" to the url for small screen
  addMobile() {
    const width = Math.min(window.innerWidth, window.screen.width);

    const url = this.#addIsMobileTo(this.urlValue);
    this.element.src = url.toString();
  }

  showLoading(ev) {
    // Turbo requests from forms within the frame bubble up here too, only the frame's own
    // requests (e.g. changing page) replace the products
    if (ev?.target && ev.target !== this.element) return;

    // Wait for 100ms to display the loading spinner, if request load faster than 100ms
    // it won't show the loading spinner making the page feel snappy
    this.timeoutID = setTimeout(() => {
      this.loadingTarget.style.display = "block";
      if (this.hasProductsTarget) {
        this.productsTarget.style.display = "none";
      }
    }, 100);
  }

  // Bring the start of the list back into view after changing page
  scrollToTop() {
    clearTimeout(this.timeoutID);

    // use window.scrollTo to apply an offset to take into account the nav bar and the search bar
    const navElement = document.getElementsByTagName("nav")[0];
    const searchElement = document.getElementsByClassName("shop-searchbar")[0];
    const toggleElement = document.getElementsByClassName("left-off-canvas-toggle")[0];

    if (navElement === undefined) {
      this.element.scrollIntoView({ behavior: "smooth", block: "start" });
      return;
    }

    const headerOffset =
      navElement.offsetHeight + searchElement.offsetHeight + toggleElement.offsetHeight;
    const elementPosition = this.element.getBoundingClientRect().top;
    const offsetPosition = elementPosition + window.pageYOffset - headerOffset;

    window.scrollTo({
      top: offsetPosition,
      behavior: "smooth",
    });
  }

  // private

  #addIsMobileTo(url) {
    const origin = new URL(window.location.href).origin;
    const parsedUrl = new URL(url, origin);

    if (parsedUrl.searchParams.has("mobile")) return parsedUrl;

    const width = Math.min(window.innerWidth, window.screen.width);

    if (width < this.maxWidthValue) {
      parsedUrl.searchParams.append("mobile", true);
    }

    return parsedUrl;
  }
}
