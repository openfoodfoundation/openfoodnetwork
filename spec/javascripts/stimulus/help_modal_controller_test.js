/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import help_modal_controller from "../../../app/webpacker/controllers/help_modal_controller";
import help_modal_link_controller from "../../../app/webpacker/controllers/help_modal_link_controller";

expect.extend({
  toBeVisible(element) {
    if(element.className.includes("in") && element.style.display == "block") {
      return { pass: true }
    } else {
      return { pass: false }
    }
  },
});

describe("HelpModalController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("help-modal", help_modal_controller);
    application.register("help-modal-link", help_modal_link_controller);
    jest.useFakeTimers()
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="help-modal-controller" data-controller="help-modal"
           data-action="keyup@document->help-modal#closeIfEscapeKey">
        <div id="background"
             class="reveal-modal-bg.fade"
             data-help-modal-target="background"
             data-action="click->help-modal#close">
        </div>
        <div id="modal"
             class="reveal-modal.fade.medium.help-modal"
             data-help-modal-target="modal">
          Hello world
          <a id="close-link" data-action="click->help-modal#close">Close</a>
        </div>
      </div>

      <a id="open-link"
         data-controller="help-modal-link"
         data-action="click->help-modal-link#open"
         data-help-modal-link-target-value="help-modal-controller">
        Open
      </a>
    `;
  });

  it("opens and closes", () => {
    const modal = document.getElementById("modal");
    const openLink = document.getElementById("open-link");
    const closeLink = document.getElementById("close-link");
    expect(document.body.className).not.toContain("modal-open")
    expect(background).not.toBeVisible()
    expect(modal).not.toBeVisible()

    openLink.click();
    jest.runAllTimers();

    expect(document.body.className).toContain("modal-open")
    expect(background).toBeVisible()
    expect(modal).toBeVisible()

    closeLink.click();
    jest.runAllTimers();

    expect(document.body.className).not.toContain("modal-open")
    expect(background).not.toBeVisible()
    expect(modal).not.toBeVisible()
  });

  it("closes when the escape key is pressed", () => {
    const modal = document.getElementById("modal");
    const openLink = document.getElementById("open-link");
    openLink.click();
    jest.runAllTimers()
    expect(modal).toBeVisible()

    document.dispatchEvent(new KeyboardEvent('keyup', { 'code': 'Escape' }));
    jest.runAllTimers()

    expect(modal).not.toBeVisible()
  });

  it("closes when the background is clicked", () => {
    const background = document.getElementById("background");
    const modal = document.getElementById("modal");
    const openLink = document.getElementById("open-link");
    openLink.click();
    jest.runAllTimers()
    expect(modal).toBeVisible()

    background.click()
    jest.runAllTimers()

    expect(modal).not.toBeVisible()
  });
});

