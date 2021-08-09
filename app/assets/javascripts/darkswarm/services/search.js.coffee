angular.module('Darkswarm').factory "Search", ($location)->
  new class Search
    search: (query = false)->
      if query
        $location.search('query', query)
      else if query == ""
        $location.search('query', null)
      else
        $location.search()['query']
