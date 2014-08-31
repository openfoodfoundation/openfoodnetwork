Darkswarm.directive "renderSvg", ()->
  restrict: 'E'
  priority: 99
  template: "<svg-wrapper></svg-wrapper>"
  link: (scope, elem, attr)->
    if /.svg/.test attr.path # Only do this if we've got an svg
      $.ajax
        url: attr.path
        success: (html)->
          elem.html($(html).find("svg"))
