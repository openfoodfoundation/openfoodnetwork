# Parses a structure of errors that came from the server
angular.module("admin.utils").factory "ErrorsParser", ->
  new class ErrorsParser
    toString: (errors, defaultContent = "") =>
      if errors.length > 0
        # it is an array of errors
        errorsString = error + "\n" for error in errors
      else
        # it is a hash of errors
        keys = Object.keys(errors)
        errorsString = ""
        for key in keys
          errorsString += error for error in errors[key]

        errorsString = defaultContent if errorsString == ""

      errorsString
