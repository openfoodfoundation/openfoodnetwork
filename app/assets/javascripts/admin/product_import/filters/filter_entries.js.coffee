angular.module("ofn.admin").filter 'entriesFilterValid', ->
  (entries, type) ->
    if type == 'all'
      return entries

    filtered = {}

    angular.forEach entries, (entry, line_number) ->
      validates_as = entry.validates_as
      if type == 'valid' and (validates_as != '')
        filtered[line_number] = entry
      if type == 'invalid' and (validates_as == '')
        filtered[line_number] = entry
      if type == 'create_product' and (validates_as == 'new_product' or validates_as == 'new_variant')
        filtered[line_number] = entry
      if type == 'update_product' and validates_as == 'existing_variant'
        filtered[line_number] = entry
      if type == 'create_inventory' and validates_as == 'new_inventory_item'
        filtered[line_number] = entry
      if type == 'update_inventory' and validates_as == 'existing_inventory_item'
        filtered[line_number] = entry

    filtered

angular.module("ofn.admin").filter 'entriesFilterSupplier', ->
  (entries, supplier) ->
    if supplier == 'all'
      return entries

    filtered = {}

    angular.forEach entries, (entry, line_number) ->
      if supplier == entry.attributes['supplier']
        filtered[line_number] = entry

    filtered
