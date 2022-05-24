import TomSelectController from "./tom_select_controller";

export default class extends TomSelectController {
  static values = { options: Object, distributor: Number };

  connect() {
    const options = {
      valueField: "id",
      labelField: "email",
      searchField: ["email", "full_name", "last_name"],
      load: this.load.bind(this),
      shouldLoad: (query) => query.length > 2,
      render: {
        option: this.renderOption.bind(this),
      },
    };
    super.connect(options);
    this.control.on("item_add", this.onItemSelect.bind(this));
    this.items = [];
  }

  load(query, callback) {
    var params = {
      q: query,
      distributor_id: this.distributorValue,
    };

    fetch("/admin/search/customers.json?" + new URLSearchParams(params))
      .then((response) => response.json())
      .then((json) => {
        this.items = json;
        callback(json);
      })
      .catch((error) => {
        this.items = [];
        console.log(error);
        callback();
      });
  }

  renderOption(item, escape) {
    if (!item.bill_address) {
      return this.renderWithNoBillAddress(item, escape);
    }
    return `<div class='customer-autocomplete-item'>
              <div class='customer-details'>
                <h5>${escape(item.email)}</h5>
                ${
                  item.bill_address.firstname
                    ? `<strong>${I18n.t("bill_address")}</strong>
                    ${item.bill_address.firstname} ${
                        item.bill_address.lastname
                      }<br>
                    ${item.bill_address.address1}, ${
                        item.bill_address.address2
                      }<br>
                    ${item.bill_address.city}
                    <br>
                  ${
                    item.bill_address.state_id &&
                    item.bill_address.state &&
                    item.bill_address.state.name
                      ? item.bill_address.state.name
                      : item.bill_address.state_name
                  }
                    
                  ${
                    item.bill_address.country && item.bill_address.country.name
                      ? item.bill_address.country.name
                      : item.bill_address.country_name
                  }
                  `
                    : ""
                }
              </div>
            </div>`;
  }

  renderWithNoBillAddress(item, escape) {
    return `<div class='customer-autocomplete-item'>
              <div class='customer-details'><h5>${escape(item.email)}</h5></div>
            </div>`;
  }

  onItemSelect(id, item) {
    const customer = this.items.find((item) => item.id == id);
    ["bill_address", "ship_address"].forEach((address) => {
      const data = customer[address];
      const address_parts = [
        "firstname",
        "lastname",
        "address1",
        "address2",
        "city",
        "zipcode",
        "phone",
      ];
      const attribute_wrapper = "#order_" + address + "_attributes_";
      address_parts.forEach((part) => {
        document.querySelector(attribute_wrapper + part).value = data
          ? data[part]
          : "";
      });
      this.setValueOnTomSelectController(
        document.querySelector(attribute_wrapper + "state_id"),
        data ? data.state_id : ""
      );
      this.setValueOnTomSelectController(
        document.querySelector(attribute_wrapper + "country_id"),
        data ? data.country_id : ""
      );
    });
    $("#order_email").val(customer.email);
    $("#user_id").val(customer.user_id);
  }

  setValueOnTomSelectController = (element, value) => {
    if (!value) {
      return;
    }
    this.application
      .getControllerForElementAndIdentifier(element, "tom-select")
      .control.setValue(value, true);
  };
}
