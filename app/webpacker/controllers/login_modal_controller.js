import { Controller } from "stimulus"
import CableReady from "cable_ready"

export default class extends Controller {
  static targets = ["background", "modal", "email"]
  static values = { email: String }

  connect() {
    if(this.hasModalTarget) {
      window.addEventListener("login:modal:open", this.open)

      if(location.hash.substr(1).includes("/login")) {
        this.open()
      }
    }
  }

  call(event) {
    event.preventDefault()
    window.dispatchEvent(new Event("login:modal:open"))
  }

  emailOnInput(event) {
    this.emailValue = event.currentTarget.value
    this.emailTargets.forEach((element) => {
      element.value = this.emailValue
    })
  }

  open = () => {
    if(!location.hash.substr(1).includes("/login")) {
      history.pushState({}, "", "#/login")
    }

    this.backgroundTarget.style.display = "block"
    this.modalTarget.style.display = "block"

    document.querySelector("body").classList.add("modal-open")

    setTimeout(() => {
      this.modalTarget.classList.add("in")
      this.backgroundTarget.classList.add("in")
    })

    window._paq?.push(['trackEvent', 'Signin/Signup', 'Login Modal View', window.location.href])
  }

  close() {
    history.pushState({}, "", window.location.pathname + window.location.search)

    this.modalTarget.classList.remove("in")
    this.backgroundTarget.classList.remove("in")

    document.querySelector("body").classList.remove("modal-open")

    setTimeout(() => {
      this.backgroundTarget.style.display = "none"
      this.modalTarget.style.display = "none"
    }, 200)
  }

  resend_confirmation() {
    fetch("/user/spree_user/confirmation", {
      method: "POST",
      body: JSON.stringify({
        spree_user: { email: this.emailValue }
      })
    }).then(data => data.json()).then(CableReady.perform)
  }

  returnHome() {
    window.location = "/"
  }

  disconnect() {
    if(this.hasModalTarget) {
      window.removeEventListener("login:modal:open", this.open)
    }
  }
}
