export const useSearchCustomer = (controller) => {
  Object.assign(controller, {
    load: function (query, callback) {
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
    },
  });
};
