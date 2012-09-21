/**
 * Update the price on the product details page in real time when the variant or the quantity are changed.
 **/

$(document).ready(function() {
  // Product page with variant choice
  $("#product-variants input[type='radio']").change(products_update_price_with_variant);
  $("#quantity").change(products_update_price_with_variant);
  $("#quantity").change();

  // Product page with master price only
  $(".add-to-cart input.title:not(#quantity):not(.max_quantity)").change(products_update_price_without_variant).change();
});


function products_update_price_with_variant() {
  var variant_price = $("#product-variants input[type='radio']:checked").parent().find("span.price").html();
  variant_price = variant_price.substr(2, variant_price.length-3);

  var quantity = $("#quantity").val();

  $("#product-price span.price").html("$"+(parseFloat(variant_price) * parseInt(quantity)).toFixed(2));
}


function products_update_price_without_variant() {
  var master_price = $("#product-price span.price").data('master-price');
  if(master_price == null) {
    // Store off the master price
    master_price = $("#product-price span.price").html();
    master_price = master_price.substring(1);
    $("#product-price span.price").data('master-price', master_price);
  }

  var quantity = $(this).val();

  $("#product-price span.price").html("$"+(parseFloat(master_price)*parseInt(quantity)).toFixed(2));
}
