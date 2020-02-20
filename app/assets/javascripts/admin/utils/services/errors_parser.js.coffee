# Parses a structure of errors that came from the server
angular.module("admin.utils").factory "ErrorsParser", ->
  new class ErrorsParser
    toString: (errors, defaultContent = "") =>
      return defaultContent unless errors?

      errorsString = ""
      if errors.length > 0
        # it is an array of errors
        errorsString = errors.join("\n") + "\n"
      else
        # it is a hash of errors
        keys = Object.keys(errors)
        for key in keys
          errorsString += errors[key].join("\n") + "\n"

      this.defaultIfEmpty(errorsString, defaultContent)

    defaultIfEmpty: (content, defaultContent) =>
      return defaultContent if content == ""
      content
