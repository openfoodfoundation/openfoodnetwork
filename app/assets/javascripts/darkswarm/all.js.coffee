#= require jquery
#= require jquery_ujs
#= require jquery-ui
#= require spin
#
#= require angular
#= require angular-cookies
#= require angular-resource
#= require ../shared/mm-foundation-tpls-0.2.0-SNAPSHOT
#= require ../shared/bindonce.min.js
#= require ../shared/ng-infinite-scroll.min.js
#= require ../shared/angular-local-storage.js
#= require ../search/jquery.backstretch.js
#= require angular-backstretch.js
#= require angular-flash.min.js
#= require moment
#
#= require foundation
#= require ./darkswarm
#= require ./overrides
#= require_tree ./mixins
#= require_tree ./directives
#= require_tree .

$ ->
  # Hacky fix for issue - http://foundation.zurb.com/forum/posts/2112-foundation-5100-syntax-error-in-js
  Foundation.set_namespace = ->
    null
  $(document).foundation()
