# Parses a structure of errors that came from the server
angular.module("admin.utils").factory "ErrorsParser", ->
  new class ErrorsParser
    toString: (errors, defaultContent = "") =>
      return defaultContent unless errors?

      errorsString = ""
      if Array.isArray(errors)
        # it is an array of errors
        errorsString = errors.join("\n") + "\n"
      else if typeof errors == "object"
        # it is a hash of errors
        keys = Object.keys(errors)
        for key in keys
          errorsString += errors[key].join("\n") + "\n"
      else # string
        errorsString = errors
      this.defaultIfEmpty(errorsString, defaultContent)

    defaultIfEmpty: (content, defaultContent) =>
      return defaultContent if content == ""
      content
