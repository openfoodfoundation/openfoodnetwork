angular.module("admin.enterprises")
  .factory 'Enterprise', (enterprise) ->
    new class Enterprise
      enterprise: enterprise