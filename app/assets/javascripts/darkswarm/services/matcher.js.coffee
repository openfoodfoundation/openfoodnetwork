Darkswarm.factory "Matcher", ->
  # Match text fragment in an array of strings.
  new class Matcher
    match: (properties, text)->
      properties.some (prop)->
        prop ||= ""
        prop.toLowerCase().indexOf(text.toLowerCase()) != -1
