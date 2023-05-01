/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus"
import toggle_button_disabled_controller from "../../../app/webpacker/controllers/toggle_button_disabled_controller"

describe("ButtonEnableToggleController", () => {
  beforeAll(() => {
    const application = Application.start()
    application.register("toggle-button-disabled", toggle_button_disabled_controller)
    jest.useFakeTimers()
  })

  beforeEach(() => {
    document.body.innerHTML = `
      <form id="test-form" data-controller="toggle-button-disabled">
        <input id="test-input" type="input" data-action="input->toggle-button-disabled#inputIsChanged" />
        <input id="test-submit" type="submit" data-toggle-button-disabled-target="button"/>
      </form>
    `
  })

  describe("#connect", () => {
    it("disables the target submit button", () => {
      jest.runAllTimers();

      const submit = document.getElementById("test-submit")
      expect(submit.disabled).toBe(true)
    })  

    describe("when no button present", () => {
      beforeEach(() => {
        document.body.innerHTML = `
          <form id="test-form" data-controller="toggle-button-disabled">
            <input id="test-input" type="input" data-action="input->toggle-button-disabled#inputIsChanged" />
          </form>
        `
      })

      // I am not sure if it's possible to manually trigger the loading/connect of the controller to 
      // try catch the error, so leaving as this. It will break if the missing target isn't handled
      // properly
      it("doesn't break", () => {
        jest.runAllTimers()
      })  
    })  
  })

  describe("#formIsChanged", () => {
    let input 
    let submit 

    beforeEach(() => {
      jest.runAllTimers()
      input = document.getElementById("test-input")
      submit = document.getElementById("test-submit")
    })

    describe("when the input value is not empty", () => {
      it("enables the target button", () => {
        input.value = "test"
        input.dispatchEvent(new Event("input"));

        expect(submit.disabled).toBe(false)
      })
    }) 

    describe("when the input value is empty", () => {
      it("disables the target button", () => {
        // setting up state where target button is enabled
        input.value = "test"
        input.dispatchEvent(new Event("input"));

        input.value = ""
        input.dispatchEvent(new Event("input"));

        expect(submit.disabled).toBe(true)
      })
    }) 
  })
})
