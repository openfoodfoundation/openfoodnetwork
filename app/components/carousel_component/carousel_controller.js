import Carousel from "@stimulus-components/carousel";

export default class extends Carousel {
  static targets = ["pagination", "nextButton", "prevButton"];

  get defaultOptions() {
    return {
      ...super.defaultOptions,
      navigation: this.navigationOptions(),
      pagination: this.paginationOptions(),
      a11y: {
        enabled: true,
      },
    };
  }

  navigationOptions() {
    if (!this.hasNextButtonTarget || !this.hasPrevButtonTarget) {
      return false;
    }

    return {
      nextEl: this.nextButtonTarget,
      prevEl: this.prevButtonTarget,
    };
  }

  paginationOptions() {
    if (!this.hasPaginationTarget) {
      return false;
    }

    return {
      el: this.paginationTarget,
      clickable: true,
    };
  }
}
