import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["tab", "panel", "default"];
  static values = { className: String };

  connect() {
    if (this.currentFragmentIdentifier != "") {
      this.setActivePanelFromURL();
      this.setActiveTabFromURL();
      this.setFormPanelIdentifiers(this.currentFragmentIdentifier);
    } else {
      this.panelTargets.forEach((panel) => {
        panel.style.display = "none";
      });
      this.defaultTarget.style.display = "block";
    }
  }

  changeActivePanel(event) {
    const newActivePanel = this.panelTargets.find(
      (panel) => panel.id == `${event.currentTarget.id}_panel`
    );
    this.currentActivePanel.style.display = "none";
    newActivePanel.style.display = "block";
    this.setFormPanelIdentifiers(newActivePanel.id);
  }

  changeActiveTab(event) {
    this.currentActiveTab.classList.remove(`${this.classNameValue}`);
    event.currentTarget.classList.add(`${this.classNameValue}`);
  }

  setActivePanelFromURL() {
    this.panelTargets.forEach((panel) => {
      if (panel.id == this.currentFragmentIdentifier) {
        panel.style.display = "block";
      } else {
        panel.style.display = "none";
      }
    });
  }

  setActiveTabFromURL() {
    this.tabTargets.forEach((tab) => {
      if (tab.id + "_panel" == this.currentFragmentIdentifier) {
        tab.classList.add("selected");
      } else {
        tab.classList.remove("selected");
      }
    });
  }

  // Sets value to a hidden field in the enterprise and enterprise group forms to enable redirection to same tab/panel after Update
  setFormPanelIdentifiers(identifier_value) {
    if (document.querySelector("#enterprise_panel_identifier")) {
      document.querySelector("#enterprise_panel_identifier").value =
        identifier_value;
    }
  }

  get currentActiveTab() {
    return this.tabTargets.find((tab) => tab.classList.contains("selected"));
  }

  get currentActivePanel() {
    return this.panelTargets.find(
      (panel) => panel.id == `${this.currentActiveTab.id}_panel`
    );
  }

  get currentFragmentIdentifier() {
    return window.location.hash.replace("#!#", "");
  }
}
