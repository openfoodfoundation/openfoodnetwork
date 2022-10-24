import tomSelectController from "./tom_select_controller";
export default class extends tomSelectController {
  static values = {
    url: String,
    options: Object,
  };

  static remoteDefaults = {
    valueField: "id",
    labelField: "email",
    searchField: "email",
    load: function (query, callback) {
      let url = this.urlValue + encodeURIComponent(query);
      fetch(url)
        .then((response) => response.json())
        .then((json) => {
          callback(json);
        })
        .catch(() => {
          callback();
        });
    },
  };

  connect() {
    // `this` inside remoteDefaults is different
    let boundLoad = this.constructor.remoteDefaults.load.bind(this);
    this.constructor.remoteDefaults.load = boundLoad;
    super.connect(this.constructor.remoteDefaults);
  }
}
