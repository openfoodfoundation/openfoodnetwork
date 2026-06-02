import CarouselController from "../carousel_component/carousel_controller";

export default class extends CarouselController {
  static targets = ["thumbnail", ...CarouselController.targets];

  connect() {
    super.connect();
    this.#setActiveThumbnail(this.#currentIndex());

    if (this.swiper) {
      this.swiper.on("slideChange", this.#onSlideChange);
    }
  }

  disconnect() {
    if (this.swiper) {
      this.swiper.off("slideChange", this.#onSlideChange);
    }

    super.disconnect();
  }

  goTo(event) {
    const index = Number.parseInt(event.currentTarget.dataset.slideIndex, 10);

    if (Number.isNaN(index) || !this.swiper) {
      return;
    }

    if (typeof this.swiper.slideToLoop === "function") {
      this.swiper.slideToLoop(index);
    } else {
      this.swiper.slideTo(index);
    }

    this.#setActiveThumbnail(index);
  }

  #onSlideChange = () => {
    this.#setActiveThumbnail(this.#currentIndex());
  };

  #currentIndex() {
    if (!this.swiper) {
      return 0;
    }

    return Number.isInteger(this.swiper.realIndex)
      ? this.swiper.realIndex
      : this.swiper.activeIndex;
  }

  #setActiveThumbnail(activeIndex) {
    this.thumbnailTargets.forEach((thumbnail, index) => {
      const isActive = index === activeIndex;

      thumbnail.classList.toggle("is-active", isActive);
      thumbnail.setAttribute("aria-pressed", isActive.toString());
    });
  }
}
