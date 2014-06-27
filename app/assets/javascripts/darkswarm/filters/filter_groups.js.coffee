Darkswarm.filter "groups", (Matcher)->
  (groups, text)->
    groups ||= []
    text ?= ""

    groups.filter (group)=>
      Matcher.match([
        group.name, group.description, group.long_description 
      ], text) || group.enterprises.some (e)->
        Matcher.match [e.name], text
