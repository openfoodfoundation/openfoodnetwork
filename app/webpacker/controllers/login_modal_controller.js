import { Controller } from "stimulus"

export default class extends Controller {
  call(event) {
    event.preventDefault()
    window.dispatchEvent(new Event("login:modal:open"))
  }
}
