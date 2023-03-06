describe 'MapCentreCalculator service', ->
  MapCentreCalculator = null
  Enterprises = null
  defaultLongitude = null
  defaultLatitude = null

  beforeEach ->
    module 'Darkswarm'
    module('admin.enterprises')
    defaultLongitude = -6
    defaultLatitude = 53
    angular.module('Darkswarm').value 'openStreetMapConfig', {
      open_street_map_default_latitude: 76.26,
      open_street_map_default_longitude: -42.66
    }

    inject (_MapCentreCalculator_, _Enterprises_)->
      MapCentreCalculator = _MapCentreCalculator_
      Enterprises = _Enterprises_

  describe "initialLatitude", ->
    it "calculates the center latitude of any present geocoded enterprises", ->
      Enterprises.geocodedEnterprises = -> [
        { latitude: 53, longitude: defaultLongitude },
        { latitude: 54, longitude: defaultLongitude }
      ]

      expect(MapCentreCalculator.initialLatitude()).toEqual 53.5

    it "returns the default configured latitude when there are no geocoded enterprises present", ->
      Enterprises.geocodedEnterprises = -> []

      expect(MapCentreCalculator.initialLatitude()).toEqual 76.26

  describe "initialLongitude", ->
    it "calculates the center longitude of any present geocoded enterprises", ->
      Enterprises.geocodedEnterprises = -> [
        { latitude: defaultLatitude, longitude: -6 },
        { latitude: defaultLatitude, longitude: -7 }
      ]

      expect(MapCentreCalculator.initialLongitude()).toEqual -6.5

    it "returns the default configured longitude when there are no geocoded enterprises present", ->
      Enterprises.geocodedEnterprises = -> []

      expect(MapCentreCalculator.initialLongitude()).toEqual -42.66

  describe "_calculate", ->
    it "calculates the average angle correctly when given a single angle", ->
      coordinates = [
        { latitude: defaultLatitude, longitude: -7 }
      ]

      expect(MapCentreCalculator._calculate("longitude", coordinates)).toEqual -7

    it "calculates the centre correctly when given a set of positive angles", ->
      coordinates = [
        { latitude: 53, longitude: defaultLongitude },
        { latitude: 54, longitude: defaultLongitude }
      ]

      expect(MapCentreCalculator._calculate("latitude", coordinates)).toEqual 53.5

    it "calculates the centre correctly when given a set of negative angles", ->
      coordinates = [
        { latitude: defaultLatitude, longitude: -6 },
        { latitude: defaultLatitude, longitude: -7 }
      ]

      expect(MapCentreCalculator._calculate("longitude", coordinates)).toEqual -6.5

    it "calculates the centre correctly when given a mixture of positive and negative angles and the centre is positive", ->
      coordinates = [
        { latitude: defaultLatitude, longitude: 7 },
        { latitude: defaultLatitude, longitude: -4 }
      ]

      expect(MapCentreCalculator._calculate("longitude", coordinates)).toEqual 1.5

    it "calculates the centre correctly when given a mixture of positive and negative angles and the centre is negative", ->
      coordinates = [
        { latitude: defaultLatitude, longitude: 4 },
        { latitude: defaultLatitude, longitude: -7 }
      ]

      expect(MapCentreCalculator._calculate("longitude", coordinates)).toEqual -1.5
