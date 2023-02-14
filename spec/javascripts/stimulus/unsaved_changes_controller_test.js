/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus"
import unsaved_changes_controller from "../../../app/webpacker/controllers/unsaved_changes_controller"

describe("UnsavedChangesController", () => {
  beforeAll(() => {
    const application = Application.start()
    application.register("unsaved-changes", unsaved_changes_controller)
  })

  beforeEach(() => {
    document.body.innerHTML = `
      <form 
        id="test-form" 
        data-controller="unsaved-changes" 
        data-action="beforeunload@window->unsaved-changes#leavingPage turbolinks:before-visit@window->unsaved-changes#leavingPage" 
        data-unsaved-changes-changed="false"
      >
        <input id="test-checkbox" type="checkbox" />
        <input id="test-submit" type="submit"/>
      </form>
    `
  })

  describe("#connect", () => {
    describe("when disable-submit-button is true", () => {
      beforeEach(() => {
        document.body.innerHTML = `
          <form 
            id="test-form" 
            data-controller="unsaved-changes" 
            data-action="beforeunload@window->unsaved-changes#leavingPage turbolinks:before-visit@window->unsaved-changes#leavingPage" 
            data-unsaved-changes-changed="false" 
            data-unsaved-changes-disable-submit-button="true"
          >
            <input id="test-checkbox" type="checkbox" />
            <input id="test-submit" type="submit"/>
          </form>
        `
      })

      it("disables any submit button", () => {
        const submit = document.getElementById("test-submit")

        expect(submit.disabled).toBe(true)
      })  
    })  

    describe("when disable-submit-button is false", () => {
      beforeEach(() => {
        document.body.innerHTML = `
          <form 
            id="test-form" 
            data-controller="unsaved-changes" 
            data-action="beforeunload@window->unsaved-changes#leavingPage turbolinks:before-visit@window->unsaved-changes#leavingPage" 
            data-unsaved-changes-changed="false" 
            data-unsaved-changes-disable-submit-button="false"
          >
            <input id="test-checkbox" type="checkbox" />
            <input id="test-submit" type="submit"/>
          </form>
        `
      })

      it("doesn't disable any submit button", () => {
        const submit = document.getElementById("test-submit")

        expect(submit.disabled).toBe(false)
      })  
    })  

    describe("when disable-submit-button is not set", () => {
      it("doesn't disable any submit button", () => {
        const submit = document.getElementById("test-submit")

        expect(submit.disabled).toBe(false)
      })  
    })  
  })

  describe("#formIsChanged", () => {
    let checkbox
    let submit 

    beforeEach(() => {
      checkbox = document.getElementById("test-checkbox")
      submit = document.getElementById("test-submit")
    })

    it("changed is set to true", () => {
      const form = document.getElementById("test-form")

      checkbox.click()

      expect(form.dataset.unsavedChangesChanged).toBe("true")
    })

    describe("when disable-submit-button is true", () => {
      it("enables any submit button", () => {
        checkbox.click()

        expect(submit.disabled).toBe(false)
      })
    })

    describe("when disable-submit-button is false", () => {
      it("does nothing", () => {
        expect(submit.disabled).toBe(false)

        checkbox.click()

        expect(submit.disabled).toBe(false)
      })
    })
  })

  describe('#leavingPage', () => {
    let checkbox

    beforeEach(() => {
      // Add a mock I18n object to
      const mockedT = jest.fn()
      mockedT.mockImplementation((string) => (string))

      global.I18n =  {
        t: mockedT
      }

      checkbox = document.getElementById("test-checkbox")
    })

    afterEach(() => {
      delete global.I18n
    })

    describe('when triggering a beforeunload event', () => {
      it("triggers leave page pop up when leaving page and form has been interacted with", () => {
        // interact with the form
        checkbox.click()

        // trigger beforeunload to simulate leaving the page
        const beforeunloadEvent = new Event("beforeunload")
        window.dispatchEvent(beforeunloadEvent)

        // Test the event returnValue has been set, we don't really care about the value as
        // the brower will ignore it 
        expect(beforeunloadEvent.returnValue).toBeTruthy()
      })
    })

    describe('when triggering a turbolinks:before-visit event', () => {
      let confirmSpy

      beforeEach(() => {
        confirmSpy = jest.spyOn(window, 'confirm')
      })

      afterEach(() => {
        // cleanup
        confirmSpy.mockRestore()
      })

      it("triggers a confirm popup up when leaving page and form has been interacted with", () => {
        confirmSpy.mockImplementation((msg) => {})

        // interact with the form
        checkbox.click()

        // trigger turbolinks:before-visit to simulate leaving the page
        const turbolinkEv = new Event("turbolinks:before-visit")
        window.dispatchEvent(turbolinkEv)

        expect(confirmSpy).toHaveBeenCalled()
      })

      it("stays on the page if user clicks cancel on the confirm popup", () => {
        // return false to simulate a user clicking on cancel
        confirmSpy.mockImplementation((msg) => (false)) 

        // interact with the form
        checkbox.click()

        // trigger turbolinks:before-visit to simulate leaving the page
        const turbolinkEv = new Event("turbolinks:before-visit")
        const preventDefaultSpy = jest.spyOn(turbolinkEv, 'preventDefault')

        window.dispatchEvent(turbolinkEv)

        expect(confirmSpy).toHaveBeenCalled()
        expect(preventDefaultSpy).toHaveBeenCalled()
      })
    })
  })

  describe('#handleSubmit', () => {
    let checkbox

    beforeEach(() => {
      // Add a mock I18n object to
      const mockedT = jest.fn()
      mockedT.mockImplementation((string) => (string))

      global.I18n =  {
        t: mockedT
      }

      checkbox = document.getElementById("test-checkbox")
    })

    afterEach(() => {
      delete global.I18n
    })

    describe('when submiting the form', () => {
      it("changed is set to true", () => {
        const form = document.getElementById("test-form")

        // interact with the form
        checkbox.click()

        // submit the form 
        const submitEvent = new Event("submit")
        form.dispatchEvent(submitEvent)

        expect(form.dataset.unsavedChangesChanged).toBe("false")
      })
    })
  })
})
