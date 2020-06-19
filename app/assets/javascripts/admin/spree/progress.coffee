$(document).ready ->
  $(document).ajaxStart ->
    $("#progress").fadeIn()

  $(document).ajaxStop ->
    $("#progress").fadeOut()

