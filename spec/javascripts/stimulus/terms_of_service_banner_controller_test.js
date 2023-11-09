/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus"
import terms_of_service_banner_controller from "../../../app/webpacker/controllers/terms_of_service_banner_controller"

describe("TermsOfServiceBannerController", () => {
  beforeAll(() => {
    const application = Application.start()
    application.register("terms-of-service-banner", terms_of_service_banner_controller)
  })

  beforeEach(() => {
    document.body.innerHTML = `
      <meta content="abc123authenticitytoken" name="csrf-token">
      <div 
        id="test-controller-div" 
        data-controller="terms-of-service-banner" 
        data-terms-of-service-banner-url-value="admin/users/10/accept_terms_of_service"
      >
        <div>
          <span>Terms of service has been updated </span> 
          <button id="test-accept-banner" data-action="click->terms-of-service-banner#accept">
            Accept terms of service
          </button>
          <button id="test-close-banner" data-action="click->terms-of-service-banner#close_banner">close</button>
        </div>
      </div>
    `
  })

  describe("#close", () => {
    it("removes the banner", () => {
      const closeButton = document.getElementById("test-close-banner")
      closeButton.click()
      
      expect(document.getElementById("test-controller-div")).toBeNull()
    })
  })

  describe("#accept", () => {
    it("fires a request to accept terms of service", () => {
      const mockFetch = jest.fn().mockImplementation( (_url, _options) =>
        Promise.resolve({
          ok: true,
          json: () => "",
        })
      )
      window.fetch = (_url, _options) => {
        return mockFetch(_url, _options)
      }

      const button = document.getElementById("test-accept-banner")

      button.click()
     
      expect(mockFetch).toHaveBeenCalledWith(
        "admin/users/10/accept_terms_of_service",
        { headers: { "X-CSRF-Token": "abc123authenticitytoken" }, method: "post" }
      )
    })
  })
})
