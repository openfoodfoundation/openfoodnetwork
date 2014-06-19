@google =
  maps:
    event:
      addDomListener: ->
      addDomListenerOnce: ->
      addListener: ->
      addListenerOnce: ->
      bind: ->
      clearInstanceListeners: ->
      clearListeners: ->
      forward: ->
      removeListener: ->
      trigger: ->
      vf: ->

class google.maps.LatLng
  constructor: (lat, lng) ->
    @latitude  = parseFloat(lat)
    @longitude = parseFloat(lng)

  lat: -> @latitude
  lng: -> @longitude

class google.maps.LatLngBounds
  constructor: (@ne, @sw) ->

  getSouthWest: -> @sw
  getNorthEast: -> @ne

class google.maps.OverlayView

class google.maps.Marker
  getAnimation: ->
  getClickable: ->
  getCursor: ->
  getDraggable: ->
  getFlat: ->
  getIcon: ->
  getPosition: ->
  getShadow: ->
  getShape: ->
  getTitle: ->
  getVisible: ->
  getZIndex: ->
  setAnimation: ->
  setClickable: ->
  setCursor: ->
  setDraggable: ->
  setFlat: ->
  setIcon: ->
  setPosition: ->
  setShadow: ->
  setShape: ->
  setTitle: ->
  setVisible: ->
  setZIndex: ->
  setMap: ->
  getMap: ->

class google.maps.MarkerImage

class google.maps.Map

class google.maps.Point

class google.maps.Size

class google.maps.InfoWindow
