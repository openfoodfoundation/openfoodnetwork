# Extend the "offCanvasWrap" directive in "angular-foundation" to disable hiding of the off-canvas
# upon window resize.
#
# In some browsers for mobile devices, the address bar is automatically hidden when scrolling down
# the page. This is not workable if the height of the contents of the off-canvas exceeds the height
# of the screen, because the latter portion of the contents stays hidden to the user.
#
# However, for screens over 1024px width for which the off-canvas is not styled to be visible, we
# can proceed to hide this.
#
# https://github.com/openfoodfoundation/angular-foundation/blob/0.9.0-20180826174721/src/offcanvas/offcanvas.js
angular.module('mm.foundation.offcanvas').directive 'offCanvasWrap', ($window) ->
  {
    restrict: 'C'
    priority: 1
    link: ($scope, element, attrs) ->
      win = angular.element($window)

      # Get the scope used by the "offCanvasWrap" directive:
      # https://github.com/openfoodfoundation/angular-foundation/blob/0.9.0-20180826174721/src/offcanvas/offcanvas.js#L2
      isolatedScope = element.isolateScope()

      # Unbind hiding of the off-canvas upon window resize.
      win.unbind('resize.body', isolatedScope.hide)

      # Bind hiding of the off-canvas that only happens when screen width is over 1024px.
      win.bind 'resize.body', ->
        isolatedScope.hide() if $(window).width() > 1024

      win.bind 'click.body', (e) ->
        if e.target.closest(".left-off-canvas-menu") == null && e.target.closest(".left-off-canvas-toggle") == null
          isolatedScope.hide()
  }
