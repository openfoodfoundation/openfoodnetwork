import ApplicationController from "./application_controller";
export default class extends ApplicationController {
  static targets = ["owner", "contact", "alert"];

  connect() {
    super.connect();
    this.store = document.querySelector("#managers");
  }

  update(event) {
    this.stimulate(
      "EnterpriseManager#update",
      event.currentTarget,
      this.ownerTarget.value,
      this.contactTarget.value,
      this.managerIds
    );
  }

  createRegisteredManager(event) {
    let newManagerId = Number(event.currentTarget.value);
    if (newManagerId == 0) return;
    if (this.managerIds.includes(newManagerId))
      return alert("User is already a manager");
    this.addManagerId(newManagerId);
    this.stimulate(
      "EnterpriseManager#create_registered_manager",
      event.currentTarget
    );
  }

  createUnregisteredManager(event) {
    event.detail.response.json().then((data) => {
      this.displayAlertBox();
      this.alertTarget.classList.add("ok");

      let newManagerId = Number(data.user);
      this.addManagerId(newManagerId);
      this.stimulate(
        "EnterpriseManager#create_unregistered_manager",
        event.originalTarget,
        newManagerId
      );
    });
  }

  async displayError(event) {
    this.displayAlertBox();
    this.alertTarget.classList.add("error");
    try {
      let response = await event.detail.response.json();
      let message = await response.errors;
      this.alertTarget.innerHTML = message;
    } catch (e) {
      console.log(e);
      let message = "Sorry, something went wrong";
      this.alertTarget.innerHTML = message;
    }
  }

  remove(event) {
    let removeBtn = event.currentTarget;
    if (removeBtn.classList.contains("disabled")) return;
    let managerId = Number(removeBtn.dataset.managerId);
    this.removeManagerId(managerId);
    this.stimulate("EnterpriseManager#delete", event.currentTarget);
  }

  displayAlertBox() {
    this.alertTarget.style.display = "block";
    this.alertTarget.classList.remove("error");
    this.alertTarget.classList.remove("ok");
  }

  get managerIds() {
    return JSON.parse(this.store.dataset.managerIds);
  }

  addManagerId(id) {
    let ids = this.managerIds;
    ids.push(id);
    this.updateManagerIds(ids);
  }

  removeManagerId(id) {
    let ids = this.managerIds.filter((el) => el !== id);
    this.updateManagerIds(ids);
  }

  updateManagerIds(ids) {
    this.store.dataset.managerIds = JSON.stringify(ids);
  }
}
