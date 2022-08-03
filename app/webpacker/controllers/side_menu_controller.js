import { Controller } from "stimulus"

export default class extends Controller {

  changeActiveTab(event) {

    this.dispatch("changeActiveComponent", { detail: { 
        currentActiveTab: this.currentActiveTab,
        newActiveTab: event.currentTarget
      }})

    this.currentActiveTab.classList.remove('selected')
    event.currentTarget.classList.add('selected')
  }

  get currentActiveTab() {
    return this.element.querySelector('.selected')
  }
}
