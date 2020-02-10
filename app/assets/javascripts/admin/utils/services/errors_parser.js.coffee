# Parses a structure of errors that came from the server
angular.module("admin.utils").factory "ErrorsParser", ->
  new class ErrorsParser
    toString: (errors, defaultContent = "") =>
      return defaultContent unless errors?

      errorsString = ""
      if errors.length > 0
        # it is an array of errors
        errorsString = this.arrayToString(errors)
      else
        # it is a hash of errors
        keys = Object.keys(errors)
        for key in keys
          errorsString += this.arrayToString(errors[key])

      this.defaultIfEmpty(errorsString, defaultContent)

    arrayToString: (array) =>
      string = ""
      string += entry + "\n" for entry in array
      string

    defaultIfEmpty: (content, defaultContent) =>
      return defaultContent if content == ""
      content
