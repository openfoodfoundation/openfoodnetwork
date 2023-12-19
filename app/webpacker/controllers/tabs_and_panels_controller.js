import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["tab", "panel", "default"];
  static values = { className: String };

  connect() {
    this._activateFromWindowLocationOrDefaultPanelTarget();

    window.addEventListener("popstate", (event) => {
      this._activateFromWindowLocationOrDefaultPanelTarget();
    });
  }

  _activateFromWindowLocationOrDefaultPanelTarget() {
    // Conveniently AngularJs rewrite "example.com#panel" to "example.com#/panel"
    const hashWithoutSlash = window.location.hash.replace("/", "");
    const tabWithSameHash = this.tabTargets.find((tab) => tab.hash == hashWithoutSlash);
    if (hashWithoutSlash != "" && tabWithSameHash) {
      this._activateByHash(tabWithSameHash.hash);
    } else {
      this._activateByHash(`#${this.defaultTarget.id}`);
    }
  }

  activate(event) {
    this._activateByHash(event.currentTarget.hash);
  }

  activateDefaultPanel() {
    this._activateByHash(`#${this.defaultTarget.id}`);
  }

  _activateByHash(hash) {
    this.tabTargets.forEach((tab) => {
      if (tab.hash == hash) {
        tab.classList.add(this.classNameValue);
      } else {
        tab.classList.remove(this.classNameValue);
      }
    });
    this.panelTargets.forEach((panel) => {
      if (panel.id == hash.replace("#", "")) {
        panel.style.display = "block";
      } else {
        panel.style.display = "none";
      }
    });
  }
}
