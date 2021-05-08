
OFNShared.directive "questionMarkWithTooltip", ($tooltip)->
  # We use the $tooltip service from Angular foundation to give us boilerplate
  # Subsequently we patch the scope, template and restrictions
  tooltip = $tooltip 'questionMarkWithTooltip', 'questionMarkWithTooltip', 'click'
  tooltip.scope =
    context: "="
    key: "="
  tooltip.templateUrl = "shared/question_mark_with_tooltip_icon.html"
  tooltip.replace = true
  tooltip.restrict = 'E'
  tooltip

# This is automatically referenced via naming convention in $tooltip
OFNShared.directive 'questionMarkWithTooltipPopup', ->
  restrict: 'EA'
  replace: true
  templateUrl: 'shared/question_mark_with_tooltip.html'
  scope: false
