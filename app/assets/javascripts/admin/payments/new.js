// Override of Spree's logic in the file of the same name
// Changes made as per https://github.com/spree/spree/commit/8a3a80b08abf80fbed2fcee4b429ba1caf68baf1
// which allows the form partial in admin/payments/new to be switched using radio buttons
// We can remove this file when we reach 2.3.0

$(document).ready(function() {
  if ($("#new_payment").is("*")) {
    $('.payment_methods_radios').click(
      function() {
        $('.payment-methods').hide();
        if (this.checked) {
          $('#payment_method_' + this.value).show();
        }
      }
    );

    $('.payment_methods_radios').each(
      function() {
        if (this.checked) {
          $('#payment_method_' + this.value).show();
        } else {
          $('#payment_method_' + this.value).hide();
        }
      }
    );

    $(".card_new").radioControlsVisibilityOfElement('.card_form');

    $('select.jump_menu').change(function(){
      window.location = this.options[this.selectedIndex].value;
    });
  }
});
