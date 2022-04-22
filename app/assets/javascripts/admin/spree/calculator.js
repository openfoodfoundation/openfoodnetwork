$(function() {
  var calculator_select = $('select#calc_type');
  var original_calc_type = calculator_select.val();
  $('.calculator-settings-warning').hide();

  calculator_select.on("change", function() {
    if (calculator_select.val() === original_calc_type) {
      $('div.calculator-settings').show();
      $('.calculator-settings-warning').hide();
      $('.calculator-settings').find('input,textarea,select').prop("disabled", false);
    } else {
      $('div.calculator-settings').hide();
      $('.calculator-settings-warning').show();
      $('.calculator-settings').find('input,textarea,select').prop("disabled", true);
    }
  });
})
