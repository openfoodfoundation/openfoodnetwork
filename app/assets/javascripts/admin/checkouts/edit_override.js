$(document).ready(function() {
  if ($("#customer_search_override").length > 0) {
    $("#customer_search_override").select2({
      placeholder: Spree.translations.choose_a_customer,
      ajax: {
        url: '/admin/search/customers.json', // modified
        datatype: 'json',
        data: function(term, page) {
          return { q: term, distributor_id: $('#distributor_id').val() } // modified
        },
        results: function(data, page) {
          return { results: data }
        }
      },
      dropdownCssClass: 'customer_search',
      formatResult: formatCustomerResult,
      formatSelection: function (customer) {
        _.each(['bill_address', 'ship_address'], function(address) {
          var data = customer[address];
          address_parts = ['firstname', 'lastname',
                           'company', 'address1',
                           'address2', 'city',
                           'zipcode', 'phone']
          var attribute_wrapper = '#order_' + address + '_attributes_'
          if(data != undefined) {
            _.each(address_parts, function(part) {
              $(attribute_wrapper + part).val(data[part]);
            })

            $(attribute_wrapper + 'state_id').select2("val", data['state_id']);
            $(attribute_wrapper + 'country_id').select2("val", data['country_id']);
          }
          else {
            _.each(address_parts, function(part) {
              $(attribute_wrapper + part).val("");
            })

            $(attribute_wrapper + 'state_id').select2("val", '');
            $(attribute_wrapper + 'country_id').select2("val", '');
          }
        });

        $('#order_email').val(customer.email);
        $('#user_id').val(customer.user_id); // modified
        $('#guest_checkout_true').prop("checked", false);
        $('#guest_checkout_false').prop("checked", true);
        $('#guest_checkout_false').prop("disabled", false);

        return customer.email;
      }
    })
  }
})
