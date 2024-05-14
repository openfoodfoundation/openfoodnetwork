angular.module('Darkswarm').filter 'closedShops', ->
  (enterprises, show_closed) ->
    enterprises ||= []
    show_closed ?= false

    grouped_enterprises_ids = (enterpriseWrapper.enterprise.id for enterpriseWrapper in window.groupedEnterprises when enterpriseWrapper.enterprise?.id?)

    enterprises.filter (enterprise) ->
      enterprise_exists_in_grouped = enterprise.id in grouped_enterprises_ids

      if !enterprise_exists_in_grouped
        enterprise.active = false

      show_closed or enterprise.active or (!enterprise.is_distributor and enterprise_exists_in_grouped)
