import Carousel from "@stimulus-components/carousel";

export default class extends Carousel {
  static targets = ["pagination", "nextButton", "prevButton"];

  get defaultOptions() {
    return {
      ...super.defaultOptions,
      navigation: this.navigationOptions(),
      pagination: this.paginationOptions(),
      keyboard: {
        enabled: true,
      },
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

  previous() {
    if (!this.swiper) {
      return;
    }

    this.swiper.slidePrev();
  }

  next() {
    if (!this.swiper) {
      return;
    }

    this.swiper.slideNext();
  }

  handleKeydown(event) {
    if (event.key === "ArrowLeft") {
      event.preventDefault();
      this.previous();
    }

    if (event.key === "ArrowRight") {
      event.preventDefault();
      this.next();
    }
  }
}
