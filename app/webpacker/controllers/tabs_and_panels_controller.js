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
  }

  changeActivePanel(event) {
    const newActivePanel = this.panelTargets.find(
      (panel) => panel.id == `${event.currentTarget.id}_panel`
    );

    this.currentActivePanel.style.display = "none";
    newActivePanel.style.display = "block";
  }

  changeActiveTab(event) {
    this.currentActiveTab.classList.remove(`${this.classNameValue}`);
    event.currentTarget.classList.add(`${this.classNameValue}`);
  }

  get currentActiveTab() {
    return this.tabTargets.find((tab) => tab.classList.contains("selected"));
  }

  get currentActivePanel() {
    return this.panelTargets.find(
      (panel) => panel.id == `${this.currentActiveTab.id}_panel`
    );
  }
}
