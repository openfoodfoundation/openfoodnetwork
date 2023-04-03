export const useRenderCustomer = (controller) => {
  Object.assign(controller, {
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
                      item.bill_address.country &&
                      item.bill_address.country.name
                        ? item.bill_address.country.name
                        : item.bill_address.country_name
                    }
                    `
                      : ""
                  }
                </div>
              </div>`;
    },

    renderWithNoBillAddress(item, escape) {
      return `<div class='customer-autocomplete-item'>
                <div class='customer-details'><h5>${escape(
                  item.email
                )}</h5></div>
              </div>`;
    },
  });
};
