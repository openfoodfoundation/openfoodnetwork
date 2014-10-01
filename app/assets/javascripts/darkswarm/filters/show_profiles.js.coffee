Darkswarm.filter 'showProfiles', ()->
  (enterprises, show_profiles) ->
    enterprises ||= []
    show_profiles ?= true

    enterprises.filter (enterprise)=>
      show_profiles or enterprise.is_distributor
