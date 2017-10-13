Darkswarm.controller "AccordionCtrl", ($scope, localStorageService, $timeout, $document, CurrentHub) ->
  key = "accordion_#{$scope.order.id}#{CurrentHub.hub.id}#{$scope.order.user_id}"
  value = if localStorageService.get(key) then {} else { details: true, billing: false, shipping: false, payment: false }
  localStorageService.bind $scope, "accordion", value, key
  $scope.accordionSections = ["details", "billing", "shipping", "payment"]
  # Scrolling is confused by our position:fixed top bar - add an offset to scroll
  # to the correct location, plus 5px buffer
  offset_height = $("nav.top-bar").height() + 5

  $scope.show = (section)->
    $scope.accordion[section] = true
    # If we call scrollTo() directly after show(), when one of the accordions above the
    # scroll location is closed by show(), scrollTo() will scroll to the old location of
    # the element. Putting this in a 50 ms timeout is enough delay for the DOM to
    # have updated.
    $timeout ->
      $document.scrollTo($("##{section}"), offset_height, 500)
    , 50

  $scope.$on 'purchaseFormInvalid', (event, form) ->
    # Scroll to first invalid section
    for section in $scope.accordionSections
      if not form[section].$valid
        $scope.show section
        break
