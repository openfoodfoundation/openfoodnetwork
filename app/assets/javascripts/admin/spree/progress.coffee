$(document).ready ->
  progressTimer = null
  $(document).ajaxStart ->
    progressTimer = setTimeout ->
      $("#progress").fadeIn()
    , 500

  $(document).ajaxStop ->
    clearTimeout(progressTimer) if progressTimer?
    $("#progress").stop().hide()

