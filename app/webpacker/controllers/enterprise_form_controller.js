import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "form", "default" ]

  connect() {
    // hide all forms by default
    this.formTargets.forEach((form) => this.hide(form) )
    this.showDefaultForm()
  }

  showDefaultForm() {
    this.defaultTarget.style.display = "block"
  }

  hide(form) {
    form.style.display = "none"
  }

  show({detail: { currentActiveTab, newActiveTab }}) {
    let currentActiveForm = this.element.querySelector(`#${currentActiveTab.id}_form`)
    let newActiveForm = this.element.querySelector(`#${newActiveTab.id}_form`)

    currentActiveForm.style.display = "none"
    newActiveForm.style.display = "block"
  }

}

