import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["tab", "content"];

  select(event) {
    this.setCurrentTab(this.tabTargets.indexOf(event.currentTarget));
  }

  // private

  connect() {
    this.setCurrentTab();
  }

  setCurrentTab(tabIndex = 0) {
    this.showSelectedContent(tabIndex);
    this.setButtonActiveClass(tabIndex);
  }

  showSelectedContent(tabIndex) {
    this.contentTargets.forEach((element, index) => {
      element.hidden = index !== tabIndex;
    });
  }

  setButtonActiveClass(tabIndex) {
    this.tabTargets.forEach((element, index) => {
      if (index === tabIndex) {
        element.classList.add("active");
      } else {
        element.classList.remove("active");
      }
    });
  }
}
