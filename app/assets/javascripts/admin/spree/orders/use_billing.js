$(document).ready(function() {
  var order_use_billing_input = $('input#order_use_billing');

  var order_use_billing = function () {
    if (!order_use_billing_input.is(':checked')) {
      $('#shipping').show();
    } else {
      $('#shipping').hide();
    }
  };

  order_use_billing_input.click(function() {
    order_use_billing();
  });

  order_use_billing();
});
