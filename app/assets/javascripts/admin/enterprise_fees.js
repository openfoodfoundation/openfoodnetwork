function AdminEnterpriseFeesCtrl($scope, $http) {
  $http.get('/admin/enterprise_fees.json').success(function(data) {
    $scope.enterprise_fees = data;
  });
}









/*
// Hide calculator preference fields when calculator type changed
// Fixes 'Enterprise fee is not found' error when changing calculator type
// See spree/core/app/assets/javascripts/admin/calculator.js

$(document).ready(function() {
  // Store original value
  $("select.calculator_type").each(function(i, ct) {
    ct = $(ct);
    ct.data('original-value', ct.attr('value'));
  });

  // Hide and disable calculator fields when calculator type is changed
  $("select.calculator_type").change(function() {
    var ct = $(this);
    var cs = ct.parent().parent().find("div.calculator-settings");

    if(ct.attr('value') == ct.data('original-value')) {
      cs.show();
      cs.find("input").prop("disabled", false);

    } else {
      cs.hide();
      cs.find("input").prop("disabled", true);
    }
  });
});
*/