angular.module('Darkswarm').filter 'closedShops', ->
  (enterprises, show_closed) ->
    enterprises ||= []
    show_closed ?= false

    grouped_enterprises_ids = (enterpriseWrapper.enterprise.id for enterpriseWrapper in window.groupedEnterprises when enterpriseWrapper.enterprise?.id?)

    enterprises.filter (enterprise) ->
      show_closed or enterprise.active or !enterprise.is_distributor or grouped_enterprises_ids.includes(enterprise.id)
