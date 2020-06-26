describe 'MapCentreCalculator service', ->
  MapCentreCalculator = null
  defaultLongitude = null
  defaultLatitude = null

  beforeEach ->
    module 'Darkswarm'
    defaultLongitude = -6
    defaultLatitude = 53

    inject (_MapCentreCalculator_)->
      MapCentreCalculator = _MapCentreCalculator_

  describe "calculate_latitude", ->
    it "calculates the center latitude", ->
      coordinates = [
        { latitude: 53, longitude: defaultLongitude },
        { latitude: 54, longitude: defaultLongitude }
      ]

      expect(MapCentreCalculator.calculate_latitude(coordinates)).toEqual 53.5

  describe "calculate_longitude", ->
    it "calculates the center longitude", ->
      coordinates = [
        { latitude: defaultLatitude, longitude: -6 },
        { latitude: defaultLatitude, longitude: -7 }
      ]

      expect(MapCentreCalculator.calculate_longitude(coordinates)).toEqual -6.5

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
