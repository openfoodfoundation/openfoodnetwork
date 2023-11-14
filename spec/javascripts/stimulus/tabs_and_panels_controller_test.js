/**
 * @jest-environment jsdom
 */

import { Application } from 'stimulus';
import tabs_and_panels_controller from '../../../app/webpacker/controllers/tabs_and_panels_controller';

describe('TabsAndPanelsController', () => {
  beforeAll(() => {
    const application = Application.start();
    application.register('tabs-and-panels', tabs_and_panels_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="tabs-and-panels" data-tabs-and-panels-class-name-value="selected" data-action="orderCycleSelected@window->tabs-and-panels#activateDefaultPanel">
        <a id="peek_tab" href="#peek_panel" data-action="tabs-and-panels#activate" class="selected" data-tabs-and-panels-target="tab">Peek</a>
        <a id="ka_tab" href="#ka_panel" data-action="tabs-and-panels#activate" data-tabs-and-panels-target="tab">Ka</a>
        <a id="boo_tab" href="#boo_panel" data-action="tabs-and-panels#activate" data-tabs-and-panels-target="tab">Boo</a>

        <div id="peek_panel" data-tabs-and-panels-target="panel default">Peek me</div>
        <div id="ka_panel" data-tabs-and-panels-target="panel">Ka you</div>
        <div id="boo_panel" data-tabs-and-panels-target="panel">Boo three</div>
      </div>`
  })

  it("#activate by clicking on tab", () => {
    const peakTab = document.getElementById("peek_tab")
    const kaTab = document.getElementById("ka_tab")
    const booTab = document.getElementById("boo_tab")
    const peakPanel = document.getElementById("peek_panel")
    const kaPanel = document.getElementById("ka_panel")
    const booPanel = document.getElementById("boo_panel")

    expect(peakTab.classList.contains("selected")).toBe(true)
    expect(kaTab.classList.contains("selected")).toBe(false)
    expect(booTab.classList.contains("selected")).toBe(false)

    expect(peakPanel.style.display).toBe("block")
    expect(kaPanel.style.display).toBe("none")
    expect(booPanel.style.display).toBe("none")

    kaTab.click()

    expect(peakTab.classList.contains("selected")).toBe(false)
    expect(kaTab.classList.contains("selected")).toBe(true)
    expect(booTab.classList.contains("selected")).toBe(false)

    expect(peakPanel.style.display).toBe("none")
    expect(kaPanel.style.display).toBe("block")
    expect(booPanel.style.display).toBe("none")
  })

  it("#activateDefaultPanel on orderCycleSelected event", () => {
    const peakTab = document.getElementById("peek_tab")
    const kaTab = document.getElementById("ka_tab")
    const booTab = document.getElementById("boo_tab")
    const peakPanel = document.getElementById("peek_panel")
    const kaPanel = document.getElementById("ka_panel")
    const booPanel = document.getElementById("boo_panel")

    expect(peakTab.classList.contains("selected")).toBe(true)
    expect(kaTab.classList.contains("selected")).toBe(false)
    expect(booTab.classList.contains("selected")).toBe(false)

    expect(peakPanel.style.display).toBe("block")
    expect(kaPanel.style.display).toBe("none")
    expect(booPanel.style.display).toBe("none")

    kaTab.click()

    expect(peakTab.classList.contains("selected")).toBe(false)
    expect(kaTab.classList.contains("selected")).toBe(true)
    expect(booTab.classList.contains("selected")).toBe(false)

    expect(peakPanel.style.display).toBe("none")
    expect(kaPanel.style.display).toBe("block")
    expect(booPanel.style.display).toBe("none")

    const event = new Event("orderCycleSelected")
    window.dispatchEvent(event);

    expect(peakTab.classList.contains("selected")).toBe(true)
    expect(kaTab.classList.contains("selected")).toBe(false)
    expect(booTab.classList.contains("selected")).toBe(false)

    expect(peakPanel.style.display).toBe("block")
    expect(kaPanel.style.display).toBe("none")
    expect(booPanel.style.display).toBe("none")
  })

  describe("when valid anchor is specified in the url", () => {
    const oldWindowLocation = window.location
    beforeAll(() => {
      Object.defineProperty(window, "location", {
        value: new URL("http://example.com/#boo_panel"),
        configurable: true,
      })
    })
    afterAll(() => {
      delete window.location
      window.location = oldWindowLocation
    })

    it("#activateFromWindowLocationOrDefaultPanelTarget show panel based on anchor", () => {
      const peakTab = document.getElementById("peek_tab")
      const kaTab = document.getElementById("ka_tab")
      const booTab = document.getElementById("boo_tab")
      const peakPanel = document.getElementById("peek_panel")
      const kaPanel = document.getElementById("ka_panel")
      const booPanel = document.getElementById("boo_panel")

      expect(peakTab.classList.contains("selected")).toBe(false)
      expect(kaTab.classList.contains("selected")).toBe(false)
      expect(booTab.classList.contains("selected")).toBe(true)

      expect(peakPanel.style.display).toBe("none")
      expect(kaPanel.style.display).toBe("none")
      expect(booPanel.style.display).toBe("block")
    })
  })

  describe("when non valid anchor is specified in the url", () => {
    const oldWindowLocation = window.location
    beforeAll(() => {
      Object.defineProperty(window, "location", {
        value: new URL("http://example.com/#non_valid_panel"),
        configurable: true,
      })
    })
    afterAll(() => {
      delete window.location
      window.location = oldWindowLocation
    })

    it("#activateFromWindowLocationOrDefaultPanelTarget show default panel", () => {
      const peakTab = document.getElementById("peek_tab")
      const kaTab = document.getElementById("ka_tab")
      const booTab = document.getElementById("boo_tab")
      const peakPanel = document.getElementById("peek_panel")
      const kaPanel = document.getElementById("ka_panel")
      const booPanel = document.getElementById("boo_panel")

      expect(peakTab.classList.contains("selected")).toBe(true)
      expect(kaTab.classList.contains("selected")).toBe(false)
      expect(booTab.classList.contains("selected")).toBe(false)

      expect(peakPanel.style.display).toBe("block")
      expect(kaPanel.style.display).toBe("none")
      expect(booPanel.style.display).toBe("none")
    })
  })
})
