angular.module("admin.enterprises").directive "ofnProducerAutocomplete", (Enterprises, $sanitize) ->
  scope: true
  link: (scope,element,attrs) ->
    multiple = scope.$eval attrs.multipleSelection
    placeholder = attrs.placeholder
    initialSelection = scope.$eval attrs.ngModel
    suppliers = scope.suppliers

    setTimeout ->
      element.select2
        placeholder: placeholder
        multiple: multiple
        initSelection: (element, callback) ->
          if multiple
            callback Enterprises.findByIDs(initialSelection)
          else
            callback Enterprises.findByID(initialSelection)
        query: (query) ->
          query.callback { results: Enterprises.findByTerm(suppliers, query.term) }
        formatResult: (producer) ->
          $sanitize(producer.name)
        formatSelection: (producer) ->
          producer.name

      #Allows drag and drop
      if multiple
        element.select2("container").find("ul.select2-choices").sortable
          containment: 'parent'
          start: -> element.select2("onSortStart")
          update: -> element.select2("onSortEnd")
