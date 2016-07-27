angular.module("admin.utils").factory "DialogDefaults", ($window) ->
  show: { effect: "fade", duration: 400 }
  hide: { effect: "fade", duration: 300 }
  autoOpen: false
  resizable: false
  width: $window.innerWidth * 0.4
  position: ['middle', 100]
  modal: true
  open: (event, ui) ->
    $('.ui-widget-overlay').bind 'click', ->
      $(this).siblings('.ui-dialog').find('.ui-dialog-content').dialog('close')
