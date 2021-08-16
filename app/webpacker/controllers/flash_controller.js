import { Controller } from "stimulus"

document.addEventListener('turbolinks:before-cache', () =>
  document.getElementById('flash').remove()
)

export default class extends Controller {
  connect() {
    setTimeout(this.fadeout.bind(this), 3000)
  }

  fadeout() {
    this.element.classList.add("animate-hide-500")
    setTimeout(this.close.bind(this), 500)
  }

  close() {
    this.element.remove()
  }
}
