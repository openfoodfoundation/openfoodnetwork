import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["tab", "content"]

  connect() {
    this.setCurrentTab()
  }

  select(event) {
    this.setCurrentTab(this.tabTargets.indexOf(event.currentTarget))
  }

  setCurrentTab(tabIndex = 0) {
    this.contentTargets.forEach((element, index) => {
      element.hidden = index !== tabIndex
    })

    this.tabTargets.forEach((element, index) => {
      if(index === tabIndex) {
        element.classList.add("active")
      } else {
        element.classList.remove("active")
      }
    })
  }
}
