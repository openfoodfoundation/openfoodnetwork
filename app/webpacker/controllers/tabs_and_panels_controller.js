import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["tab", "panel", "default"];
  static values = { className: String };

  connect() {
    // hide all active panel
    this.panelTargets.forEach((panel) => {
      panel.style.display = "none";
    });

    // only display the default panel
    this.defaultTarget.style.display = "block";

    // Display panel specified in url anchor
    const anchors = window.location.toString().split("#");
    let anchor = anchors.length > 1 ? anchors.pop() : "";

    if (anchor != "") {
      // Conveniently AngularJs rewrite "example.com#panel" to "example.com#/panel" :(
      // strip the starting / if any
      if (anchor[0] == "/") {
        anchor = anchor.slice(1);
      }
      // Add _panel to the anchor to match the panel id if needed
      if (!anchor.includes("_panel")) {
        anchor = `${anchor}_panel`;
      }
      this.updateActivePanel(anchor);

      // tab
      const tab_id = anchor.split("_panel").shift();
      this.updateActiveTab(tab_id);
    }

    window.addEventListener("tabs-and-panels:click", (event) => {
      this.simulateClick(event.detail.tab, event.detail.panel);
    });
  }

  simulateClick(tab, panel) {
    this.updateActivePanel(panel);
    this.updateActiveTab(tab);
  }

  changeActivePanel(event) {
    this.updateActivePanel(`${event.currentTarget.id}_panel`);
  }

  updateActivePanel(panel_id) {
    const newActivePanel = this.panelTargets.find((panel) => panel.id == panel_id);

    if (newActivePanel === undefined) {
      // No panel found
      return;
    }

    this.currentActivePanel.style.display = "none";
    newActivePanel.style.display = "block";
  }

  changeActiveTab(event) {
    this.currentActiveTab.classList.remove(`${this.classNameValue}`);
    event.currentTarget.classList.add(`${this.classNameValue}`);
  }

  updateActiveTab(tab_id) {
    const newActiveTab = this.tabTargets.find((tab) => tab.id == tab_id);

    if (newActiveTab === undefined) {
      // No tab found
      return;
    }

    this.currentActiveTab.classList.remove(`${this.classNameValue}`);
    newActiveTab.classList.add(`${this.classNameValue}`);
  }

  get currentActiveTab() {
    return this.tabTargets.find((tab) => tab.classList.contains("selected"));
  }

  get currentActivePanel() {
    return this.panelTargets.find((panel) => panel.id == `${this.currentActiveTab.id}_panel`);
  }
}
