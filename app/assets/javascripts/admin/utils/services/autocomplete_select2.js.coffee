angular.module("admin.utils").factory 'AutocompleteSelect2', ($sanitize) ->
  scope: true
  autocomplete: (
    multiple,
    placeholder,
    element,
    findByID,
    findByIDs,
    findByTerm
  ) ->
    element.select2
      placeholder: placeholder
      multiple: multiple  
      initSelection: (element, callback) ->
        if multiple
          callback findByIDs()
        else
          callback findByID()
      query: (query) ->
        query.callback { results: findByTerm(query.term) }
      formatResult: (item) ->
        $sanitize(item.name)
      formatSelection: (item) ->
        item.name

    #Allows drag and drop
    if multiple
      element.select2("container").find("ul.select2-choices").sortable
        containment: 'parent'
        start: -> element.select2("onSortStart")
        update: -> element.select2("onSortEnd")
