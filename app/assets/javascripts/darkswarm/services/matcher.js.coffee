Darkswarm.factory "Matcher", ->
    new class Matcher
      match: (properties, text)->
        properties.some (prop)->
          prop.toLowerCase().indexOf(text.toLowerCase()) != -1
