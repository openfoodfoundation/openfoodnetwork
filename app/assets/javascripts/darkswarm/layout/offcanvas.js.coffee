$ ->
  menu = $(".left-off-canvas-menu")
  setOffcanvasMenuHeight = ->
    menu.height($(window).height())
  $(window).on("resize", setOffcanvasMenuHeight)
  setOffcanvasMenuHeight()
