describe 'MapCentreCalculator service', ->
  MapCentreCalculator = null
  Enterprises = null

  beforeEach ->
    module 'Darkswarm'
    module('admin.enterprises')
    angular.module('Darkswarm').value 'openStreetMapConfig', {
      open_street_map_default_latitude: 76.26,
      open_street_map_default_longitude: -42.66
    }

    inject (_MapCentreCalculator_, _Enterprises_)->
      MapCentreCalculator = _MapCentreCalculator_
      Enterprises = _Enterprises_

  describe "initialBounds", ->
    it "returns null when there are no geocoded enterprises present", ->
      Enterprises.geocodedEnterprises = -> []

      expect(MapCentreCalculator.initialBounds()).toBeNull()

    it "returns the bounds of a single geocoded enterprise", ->
      Enterprises.geocodedEnterprises = -> [
        { latitude: 53, longitude: -6 }
      ]

      expect(MapCentreCalculator.initialBounds()).toEqual [[53, -6], [53, -6]]

    it "returns the bounds of all geocoded enterprises", ->
      Enterprises.geocodedEnterprises = -> [
        { latitude: 54, longitude: -7 },
        { latitude: 53, longitude: 4 },
        { latitude: -2, longitude: -6 }
      ]

      expect(MapCentreCalculator.initialBounds()).toEqual [[-2, -7], [54, 4]]

    it "ignores a far-away mis-geocoded enterprise when there are many enterprises", ->
      enterprises = ({ latitude: 43 + (i % 10), longitude: -79 - (i % 20) } for i in [0...100])
      enterprises.push { latitude: -25.25, longitude: -52.02 }
      Enterprises.geocodedEnterprises = -> enterprises

      expect(MapCentreCalculator.initialBounds()).toEqual [[43, -98], [52, -79]]

    it "keeps remote enterprises near the edge of the network", ->
      enterprises = ({ latitude: 43 + (i % 10), longitude: -79 - (i % 20) } for i in [0...100])
      enterprises.push { latitude: 47.5, longitude: -72 }
      enterprises.push { latitude: 47.6, longitude: -72 }
      enterprises.push { latitude: -25.25, longitude: -80 }
      Enterprises.geocodedEnterprises = -> enterprises

      expect(MapCentreCalculator.initialBounds()).toEqual [[43, -98], [52, -72]]

    it "keeps every enterprise when there are too few to tell outliers apart", ->
      enterprises = ({ latitude: 43, longitude: -79 } for i in [0...10])
      enterprises.push { latitude: -25.25, longitude: -52.02 }
      Enterprises.geocodedEnterprises = -> enterprises

      expect(MapCentreCalculator.initialBounds()).toEqual [[-25.25, -79], [43, -52.02]]

  describe "defaultCentre", ->
    it "returns the configured default latitude and longitude", ->
      expect(MapCentreCalculator.defaultCentre()).toEqual [76.26, -42.66]
