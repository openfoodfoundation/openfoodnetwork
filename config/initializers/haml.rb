# frozen_string_literal: true

# Haml 6 treats only a small set of standard boolean attributes as such.
# Other attributes are added in full. But AngularJS distinguishes between
#   <div ng-cloak>
# and
#   <div ng-cloak="true">
#
# The latter raises errors.
#
# Adding to these attributes is officially supported:
# - https://github.com/haml/haml/releases/tag/v6.2.2
#
Haml::BOOLEAN_ATTRIBUTES.push(
  *%w[
    mailto
    new-tag-rule-dialog
    ng-cloak
    ng-transclude
    offcanvas
    ofn-disable-enter
    question-mark-with-tooltip-animation
    scroll-after-load
  ]
)
