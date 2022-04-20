import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["background", "modal"]

  open() {
    this.backgroundTarget.style.display = "block"
    this.modalTarget.style.display = "block"

    setTimeout(() => {
      this.modalTarget.classList.add("in")
      this.backgroundTarget.classList.add("in")
      document.querySelector("body").classList.add("modal-open")
    })
  }

  close() {
    this.modalTarget.classList.remove("in")
    this.backgroundTarget.classList.remove("in")
    document.querySelector("body").classList.remove("modal-open")

    setTimeout(() => {
      this.backgroundTarget.style.display = "none"
      this.modalTarget.style.display = "none"
    }, 200)
  }

  closeIfEscapeKey(e) {
    if (e.code == "Escape") {
      this.close()
    }
  }
}
