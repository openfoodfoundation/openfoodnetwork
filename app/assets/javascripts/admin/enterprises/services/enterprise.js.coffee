angular.module("admin.enterprises")
  # Populate Enterprise.enterprise with enterprise json array from the page.
  .factory 'Enterprise', (enterprise) ->
    new class Enterprise
      enterprise: enterprise
