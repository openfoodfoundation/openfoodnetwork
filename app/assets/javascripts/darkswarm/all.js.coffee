#= require jquery
#= require jquery_ujs
#= require jquery-ui
#= require spin
#
#= require angular
#= require angular-resource
#
#= require ../shared/jquery.timeago
#= require foundation
#= require ./shop
#= require_tree .

$ ->
  $(document).foundation()
  $(document).foundation('reveal', {animation: 'fade'})
