/*
 * Original from spree/core/vendor/assets/javascripts/jquery.adaptivemenu.js
 */

/*
 * Used for the spree admin tab bar (Orders, Products, Reports etc.).
 * Using parent's width instead of window width.
 */
jQuery.fn.AdaptiveMenu = function(options){

	var options = jQuery.extend({
		text: "More...",
		accuracy:0,
		'class':null,
		'classLinckMore':null
	},options);

	var menu = this;
	var li = $(menu).find("li");

	var width = 0;
	var widthLi = [];
	$.each( li , function(i, l){
		width += $(l).width();
		widthLi.push( width );
	});

	var buildingMenu = function(){
		var windowWidth = $(menu.parent()).width()  - options.accuracy;
		for(var i = 0; i<widthLi.length; i++ ){
			if ( widthLi[i] > windowWidth )
				$( li[i] ).hide();
			else
				$( li[i] ).show();
		}
		$(menu).find('#more').remove();
		var hideLi = $(li).filter(':not(:visible)');
		var lastLi = $(li).filter(':visible').last();
		if ( hideLi.length > 0 ){
			var more = $("<li>")
				.css({"display":"inline-block","white-space":"nowrap"})
				.addClass(options.classLinckMore)
				.attr({"id":"more"})
				.html(options.text)
				.click(function(){$(this).find('li').toggle()});

			var ul =  $("<ul>")
				.css({"position":"absolute"})
				.addClass(options.klass)
				.html(hideLi.clone()).prepend(lastLi.clone().hide());

			more.append(ul);

			lastLi.hide().before(more);
		}
	}

	jQuery(window).resize(buildingMenu);

	jQuery(window).ready(buildingMenu);

};
