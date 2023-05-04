import TomSelectController from "./tom_select_controller";
import { useSearchCustomer } from "./mixins/useSearchCustomer";
import { useRenderCustomer } from "./mixins/useRenderCustomer";

export default class extends TomSelectController {
  static values = { options: Object, distributor: Number };

  connect() {
    useSearchCustomer(this);
    useRenderCustomer(this);
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
    $("#customer_id").val(customer.id);
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
