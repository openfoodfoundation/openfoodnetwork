angular.module("ofn.admin").controller "ImportFormCtrl", ($scope, $http, $filter, ProductImportService, $timeout) ->

  $scope.entries = {}
  $scope.update_counts = {}
  $scope.reset_counts = {}

  #$scope.import_options = {}

  $scope.updates = {}
  $scope.updated_total = 0
  $scope.updated_ids = []
  $scope.update_errors = []

  $scope.chunks = 0
  $scope.completed = 0
  $scope.percentage = "0%"
  $scope.started = false
  $scope.finished = false

  $scope.countResettable = () ->
    angular.forEach $scope.supplier_product_counts, (value, key) ->
      $scope.reset_counts[key] = value
      if $scope.update_counts[key]
        $scope.reset_counts[key] -= $scope.update_counts[key]

  $scope.resetProgress = () ->
    $scope.chunks = 0
    $scope.completed = 0
    $scope.percentage = "0%"
    $scope.started = false
    $scope.finished = false

  $scope.step = 'import'

  $scope.viewResults = () ->
    $scope.countResettable()
    $scope.step = 'results'
    $scope.resetProgress()

  $scope.acceptResults = () ->
    $scope.step = 'save'

  $scope.finalResults = () ->
    $scope.step = 'complete'

  $scope.start = () ->
    $scope.started = true
    $scope.percentage = "1%"
    total = $scope.item_count
    size = 100
    $scope.chunks = Math.ceil(total / size)

    i = 0

    while i < $scope.chunks
      start = (i*size)+1
      end = (i+1)*size
      if $scope.step == 'import'
        $scope.processImport(start, end)
      if $scope.step == 'save'
        $scope.processSave(start, end)
      i++

  $scope.processImport = (start, end) ->
    $http(
      url: $scope.import_url
      method: 'POST'
      data:
        'start': start
        'end': end
        'filepath': $scope.filepath
        'import_into': $scope.import_into
    ).success((data, status, headers, config) ->
      angular.merge($scope.entries, angular.fromJson(data['entries']))
      $scope.sortUpdates(data['reset_counts'])

      $scope.updateProgress()
    ).error((data, status, headers, config) ->
      console.log('Error: '+status)
    )

  $scope.importSettings = null

  $scope.getSettings = () ->
    $scope.importSettings = ProductImportService.getSettings()

  $scope.sortUpdates = (data) ->
    angular.forEach data, (value, key) ->
      if (key in $scope.update_counts)
        $scope.update_counts[key] += value['updates_count']
      else
        $scope.update_counts[key] = value['updates_count']

  $scope.processSave = (start, end) ->
    $scope.getSettings() if $scope.importSettings == null
    $http(
      url: $scope.save_url
      method: 'POST'
      data:
        'start': start
        'end': end
        'filepath': $scope.filepath
        'import_into': $scope.import_into,
        'settings': $scope.importSettings
    ).success((data, status, headers, config) ->
      $scope.sortResults(data['results'])

      angular.forEach data['updated_ids'], (id) ->
        $scope.updated_ids.push(id)

      angular.forEach data['errors'], (error) ->
        $scope.update_errors.push(error)

      $scope.updateProgress()
    ).error((data, status, headers, config) ->
      console.log('Error: '+status)
    )

  $scope.sortResults = (results) ->
    angular.forEach results, (value, key) ->
      if ($scope.updates[key] != undefined)
        $scope.updates[key] += value
      else
        $scope.updates[key] = value

      $scope.updated_total += value

  $scope.resetAbsent = () ->
    enterprises_to_reset = []
    angular.forEach $scope.importSettings, (settings, enterprise) ->
      if settings['reset_all_absent']
        enterprises_to_reset.push(enterprise)

    if enterprises_to_reset.length && $scope.updated_ids.length
      $http(
        url: $scope.reset_url
        method: 'POST'
        data:
          'filepath': $scope.filepath
          'import_into': $scope.import_into,
          'settings': $scope.importSettings
          'reset_absent': true,
          'updated_ids': $scope.updated_ids,
          'enterprises_to_reset': enterprises_to_reset
      ).success((data, status, headers, config) ->
        console.log(data)
        $scope.updates.products_reset = data

      ).error((data, status, headers, config) ->
        console.log('Error: '+status)
      )

  $scope.updateProgress = () ->
    $scope.completed++
    $scope.percentage = String(Math.round(($scope.completed / $scope.chunks) * 100)) + '%'

    if $scope.completed == $scope.chunks
      $scope.finished = true
      $scope.resetAbsent() if $scope.step == 'save'
