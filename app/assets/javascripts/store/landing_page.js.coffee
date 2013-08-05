# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->
  if $("#image-url-container").length > 0
    $('body').css('background-color', 'black', 'important');
    $.backstretch($("#image-url-container").attr("data-url"));

  # off canvas panel trigger
  events = 'click.fndtn'
  $("#sidebarButton").on events, (e) ->
    e.preventDefault()
    $("body").toggleClass "active"

  $('#new_spree_user').on 'ajax:success', (event, data, status, xhr) ->
    console.log "successfully authenticated"
