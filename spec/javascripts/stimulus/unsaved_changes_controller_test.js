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
      <form id="test-form" data-controller="unsaved-changes" data-action="beforeunload@window->unsaved-changes#leavingPage turbolinks:before-visit@window->unsaved-changes#leavingPage" data-unsaved-changes-changed="false">
        <input
          id="test-checkbox"
          type="checkbox"
          data-action="change->unsaved-changes#formIsChanged">
      </form>
    `
  })

  describe("#formIsChanged", () => {
    it("changed is set to true", () => {
      const form = document.getElementById("test-form")
      const checkbox = document.getElementById("test-checkbox")

      checkbox.click()

      expect(form.dataset.unsavedChangesChanged).toBe('true')

    })
  })

  describe('#leavingPage', () => {
    beforeEach(() => {
      // Add a mock I18n object to
      const mockedT = jest.fn()
      mockedT.mockImplementation((string) => (string))

      global.I18n =  {
        t: mockedT
      }
    })

    afterEach(() => {
      delete global.I18n
    })

    describe('when triggering a beforeunload event', () => {
      it("triggers leave page pop up when leaving page and form has been interacted with", () => {
        const checkbox = document.getElementById("test-checkbox")

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
      it("triggers a confirm popup up when leaving page and form has been interacted with", () => {
        const checkbox = document.getElementById("test-checkbox")
        const confirmSpy = jest.spyOn(window, 'confirm')
        confirmSpy.mockImplementation((msg) => {})

        // interact with the form
        checkbox.click()

        // trigger turbolinks:before-visit to simulate leaving the page
        const turbolinkEv = new Event("turbolinks:before-visit")
        window.dispatchEvent(turbolinkEv)

        expect(confirmSpy).toHaveBeenCalled()

      })

      it("stays on the page if user clicks cancel on the confirm popup", () => {
        const checkbox = document.getElementById("test-checkbox")
        const confirmSpy = jest.spyOn(window, 'confirm')
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

        // cleanup
        confirmSpy.mockRestore()
      })
    })
  })
})
