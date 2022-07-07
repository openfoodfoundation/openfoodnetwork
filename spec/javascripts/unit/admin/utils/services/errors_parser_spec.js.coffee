describe "ErrorsParser service", ->
  errorsParser = null

  beforeEach ->
    module('admin.utils')
    inject (ErrorsParser) ->
      errorsParser = ErrorsParser

  describe "toString", ->
    it "returns empty string for nil errors", ->
      expect(errorsParser.toString(null)).toEqual ""

    it  "returns string for string errors", ->
      expect(errorsParser.toString("error")).toEqual "error"

    it "returns the elements in the array if an array is provided", ->
      expect(errorsParser.toString(["1", "2"])).toEqual "1\n2\n"

    it "returns the elements in the hash if a hash is provided", ->
      expect(errorsParser.toString({ "keyname": ["1", "2"] })).toEqual "1\n2\n"

    it "returns all elements in all hash keys provided", ->
      expect(errorsParser.toString({ "keyname1": ["1", "2"], "keyname2": ["3", "4"] })).toEqual "1\n2\n3\n4\n"
