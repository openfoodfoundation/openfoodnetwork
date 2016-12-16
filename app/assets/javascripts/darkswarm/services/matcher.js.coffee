Darkswarm.factory "Matcher", ->
  new class Matcher

    # Match text fragment in an array of strings.
    match: (properties, text)->
      properties.some (prop)->
        prop ||= ""
        prop.toLowerCase().indexOf(text.toLowerCase()) != -1

    # Return true if text occurs at the beginning of any word present in an array of strings
    matchBeginning: (properties, text) ->
      text = text.trim()
      properties.some (prop) ->
        prop ||= ""
        prop.split(' ').some (word) ->
          word.toLowerCase().indexOf(text.toLowerCase()) == 0
