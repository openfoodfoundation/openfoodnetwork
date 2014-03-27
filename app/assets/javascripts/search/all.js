// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//

//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require spin
//= require foundation
//= require_tree .
//

// Hacky fix for issue - http://foundation.zurb.com/forum/posts/2112-foundation-5100-syntax-error-in-js
Foundation.set_namespace = function() {};
$(function(){ $(document).foundation(); });
