angular.module("admin.productImport").filter 'entriesFilterValid', ->
  (entries, type) ->
    if type == 'all'
      return entries

    filtered = {}

    angular.forEach entries, (entry, line_number) ->
      validates_as = entry.validates_as

      if type == 'valid' and validates_as != '' \
      or type == 'invalid' and validates_as == '' \
      or type == 'create_product' and (validates_as == 'new_product' or validates_as == 'new_variant') \
      or type == 'update_product' and validates_as == 'existing_variant' \
      or type == 'create_inventory' and validates_as == 'new_inventory_item' \
      or type == 'update_inventory' and validates_as == 'existing_inventory_item'
        filtered[line_number] = entry

    filtered

angular.module("admin.productImport").filter 'entriesFilterEnterprise', ->
  (entries, enterprise) ->
    if enterprise == 'all'
      return entries

    filtered = {}

    angular.forEach entries, (entry, line_number) ->
      if enterprise == entry.attributes['enterprise']
        filtered[line_number] = entry

    filtered
