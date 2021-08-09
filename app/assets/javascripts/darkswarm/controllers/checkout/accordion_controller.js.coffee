angular.module('Darkswarm').controller "AccordionCtrl", ($scope, localStorageService, $timeout, $document, CurrentHub) ->
  $scope.accordionSections = ["details", "billing", "shipping", "payment"]
  $scope.accordion = { details: true, billing: true, shipping: true, payment: true }

  $scope.show = (section) ->
    $scope.accordion[section] = true

  $scope.scrollTo = (section) ->
    # Scrolling is confused by our position:fixed top bar - add an offset to scroll
    # to the correct location, plus 5px buffer
    offset_height = $("nav.top-bar").height() + 5
    $document.scrollTo($("##{section}"), offset_height, 400)

  $scope.$on 'purchaseFormInvalid', (event, form) ->
    # Scroll to first invalid section
    for section in $scope.accordionSections
      if not form[section].$valid
        $scope.show section
        $timeout ->
          $scope.scrollTo(section)
        , 50
        break
