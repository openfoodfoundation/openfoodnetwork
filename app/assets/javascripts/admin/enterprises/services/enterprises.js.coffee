angular.module("admin.enterprises").factory 'Enterprises', (EnterpriseResource) ->
  new class Enterprises
    enterprises: []
    enterprises_by_id: {}
    loaded: false

    index: (params={}, callback=null) ->
    	EnterpriseResource.index params, (data) =>
        for enterprise in data
          @enterprises.push enterprise
          @enterprises_by_id[enterprise.id] = enterprise

        @loaded = true
        (callback || angular.noop)(@enterprises)

    	@enterprises
