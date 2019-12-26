$(document).ready(function() {
  if ($('#customer_autocomplete_template').length > 0) {
    window.customerTemplate = Handlebars.compile($('#customer_autocomplete_template').text());
  }
});
