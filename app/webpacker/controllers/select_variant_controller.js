import TomSelectController from "./tom_select_controller";

// This is simalar to the "variantAutocomplete" directive that uses "select2", but it doesn't
// have all the same feature
//
export default class extends TomSelectController {
  static values = { options: Object, distributor: Number, selected: Object };

  connect() {
    const options = {
      valueField: "id",
      searchField: ["name", "sku"],
      load: this.#load.bind(this),
      shouldLoad: (query) => query.length > 2,
      render: {
        option: this.#renderOption.bind(this),
        item: this.#renderItem.bind(this),
      },
    };
    super.connect(options);
    // Add the selected value if any and select it.
    // It will need to include data used in the templates below:
    // - id
    // - image
    // - name
    // - producer_name
    // - sku
    // - on_demand
    // - on_hand
    // - options_text
    //
    if (this.hasSelectedValue && Object.keys(this.selectedValue).length > 0) {
      this.control.addOption(this.selectedValue);
      this.control.addItem(this.selectedValue.id);
    }
  }

  // private

  #load(query, callback) {
    const url = "/admin/variants/search.json?q=" + encodeURIComponent(query);
    fetch(url)
      .then((response) => response.json())
      .then((json) => {
        callback(json);
      })
      .catch((error) => {
        console.log(error);
        callback();
      });
  }

  #renderOption(variant, escape) {
    return `<div class='variant-autocomplete-item'>
        <figure class='variant-image'>
          ${variant.image ? `<img src='${variant.image}' />` : "<img src='/noimage/mini.png' />"}
        </figure>
        <div class='variant-details'>
          <h6 class="variant-name">${escape(variant.name)}</h6>
          <ul>
            <li>
              <strong> ${I18n.t("spree.admin.variants.autocomplete.producer_name")}: </strong>
              ${escape(variant.producer_name)}
            </li>
          </ul>
          <ul class='variant-data'>
            <li class='variant-sku'>
              <strong>${I18n.t("admin.sku")}: </strong>
              ${escape(variant.sku)}
            </li>
            ${
              variant.on_demand
                ? `<li class='variant-on_demand'><strong>${I18n.t("on_demand")}</strong></li>`
                : `<li class='variant-on_hand'>
                     <strong>${I18n.t("on_hand")}:</strong> ${escape(variant.on_hand)}
                   </li>`
            }
            <li class='variant-options_text'>
              <strong> ${I18n.t("spree.admin.variants.autocomplete.unit")}: </strong>
              ${escape(variant.options_text)}
            </li>
          </ul>
        </div>
      </div>`;
  }

  #renderItem(variant, escape) {
    return `<span>${escape(variant.name)}</span>`;
  }
}
