import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["loading", "products"];

  updateProducts(ev) {
    const orderCycleId = ev.detail.orderCycleId;
    // Updating the turbo-frame source will reload the frame
    this.element.src = `/order_cycles/${orderCycleId}/products`;
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
    // use window.scrollTo to applay an offset to take into account the <nav> top bar's height
    // when present
    if (this.element.getBoundingClientRect().top < 0) {
      const navElement = document.getElementsByTagName("nav")[0];

      if (navElement === undefined) {
        this.element.scrollIntoView({ behavior: "smooth", block: "start" });
        return;
      }

      const headerOffset = navElement.offsetHeight;
      const elementPosition = this.element.getBoundingClientRect().top;
      const offsetPosition = elementPosition + window.pageYOffset - headerOffset;

      window.scrollTo({
        top: offsetPosition,
        behavior: "smooth",
      });
    }
  }
}
