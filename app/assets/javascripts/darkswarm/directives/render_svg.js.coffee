angular.module('Darkswarm').directive "renderSvg", ()->
  # Magical directive that'll render SVGs from URLs
  # If only there were a neater way of doing this
  restrict: 'E'
  priority: 99
  template: "<svg-wrapper></svg-wrapper>"

  # Fetch SVG via ajax, inject into page using DOM
  link: (scope, elem, attr)->
    if /.svg/.test attr.path # Only do this if we've got an svg
      $.ajax
        url: attr.path
        success: (html)->
          elem.html($(html).find("svg"))
