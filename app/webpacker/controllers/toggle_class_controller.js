import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["mark"]

  addClass(event) {
    let element = event.currentTarget
    event.params.classList.forEach((klass) => {
      this.markTarget.classList.add(klass)
    })
  }

  removeClass(event) {
    let element = event.currentTarget
    event.params.classList.forEach((klass) => {
      this.markTarget.classList.remove(klass)
    })
  }
}
