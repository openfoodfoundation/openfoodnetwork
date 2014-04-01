#= require jquery
#= require jquery_ujs
#= require jquery-ui
#= require spin
#
#= require angular
#= require angular-resource
#= require ../shared/mm-foundation-tpls-0.2.0-SNAPSHOT
#= require ../shared/bindonce.min.js
#= require ../shared/ng-infinite-scroll.min.js
#
#= require ../shared/jquery.timeago
#= require foundation
#= require ./darkswarm
#= require_tree .

$ ->
  # Hacky fix for issue - http://foundation.zurb.com/forum/posts/2112-foundation-5100-syntax-error-in-js
  Foundation.set_namespace = ->
    null
  $(document).foundation()
  $(document).foundation({reveal: {animation: 'fade'}})
