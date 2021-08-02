angular.module("admin.productImport").controller "ImportFormCtrl", ($scope, $http, $filter, ProductImportService, ams_data, $timeout) ->

  $scope.entries = {}
  $scope.update_counts = {}
  $scope.reset_counts = {}
  $scope.enterprise_product_counts = ams_data.enterprise_product_counts

  $scope.updates = {}
  $scope.updated_total = 0
  $scope.updated_ids = []
  $scope.update_errors = []

  $scope.batchSize = 50
  $scope.step = 'settings'
  $scope.chunks = 0
  $scope.completed = 0
  $scope.percentage = {
    import: "0%",
    save: "0%"
  }

  $scope.countResettable = () ->
    angular.forEach $scope.enterprise_product_counts, (value, key) ->
      $scope.reset_counts[key] = value
      if $scope.update_counts[key]
        $scope.reset_counts[key] -= $scope.update_counts[key]

  $scope.resetProgress = () ->
    $scope.chunks = 0
    $scope.completed = 0
    $scope.started = false
    $scope.finished = false

  $scope.step = 'settings'

  $scope.confirmSettings = () ->
    $scope.step = 'import'
    $scope.start()

  $scope.viewResults = () ->
    $scope.countResettable()
    $scope.step = 'results'

  $scope.acceptResults = () ->
    $scope.resetProgress()
    $scope.step = 'save'
    $scope.start()

  $scope.finalResults = () ->
    $scope.step = 'complete'

  $scope.start = () ->
    $scope.started = true
    total = ams_data.item_count
    $scope.chunks = Math.ceil(total / $scope.batchSize)

    # Process only the first batch.
    $scope.processBatch($scope.step, 0, $scope.chunks)

  $scope.processBatch = (step, batchIndex, batchCount) ->
    start = (batchIndex * $scope.batchSize) + 1
    end = (batchIndex + 1) * $scope.batchSize
    isLastBatch = batchCount == batchIndex + 1

    promise = if step == 'import'
      $scope.processImport(start, end)
    else if step == 'save'
      $scope.processSave(start, end)

    return if isLastBatch

    processNextBatch = ->
      $scope.processBatch(step, batchIndex + 1, batchCount)

    # Process next batch whether or not processing of the current batch succeeds.
    promise.then(processNextBatch, processNextBatch)

  $scope.processImport = (start, end) ->
    $http(
      url: ams_data.import_url
      method: 'POST'
      data:
        'start': start
        'end': end
        'filepath': ams_data.filepath
        'settings': ams_data.importSettings
    ).then((response) ->
      angular.merge($scope.entries, angular.fromJson(response.data['entries']))
      $scope.sortUpdates(response.data['reset_counts'])

      $scope.updateProgress()
    ).catch((response) ->
      $scope.exception = response.data
      console.error(response.data)
    )

  $scope.sortUpdates = (data) ->
    angular.forEach data, (value, key) ->
      if (key in $scope.update_counts)
        $scope.update_counts[key] += value['updates_count']
      else
        $scope.update_counts[key] = value['updates_count']

  $scope.processSave = (start, end) ->
    $http(
      url: ams_data.save_url
      method: 'POST'
      data:
        'start': start
        'end': end
        'filepath': ams_data.filepath
        'settings': ams_data.importSettings
    ).then((response) ->
      $scope.sortResults(response.data['results'])

      angular.forEach response.data['updated_ids'], (id) ->
        $scope.updated_ids.push(id)

      angular.forEach response.data['errors'], (error) ->
        $scope.update_errors.push(error)

      $scope.updateProgress()
    ).catch((response) ->
      $scope.exception = response.data
      console.error(response.data)
    )

  $scope.sortResults = (results) ->
    angular.forEach results, (value, key) ->
      if ($scope.updates[key] != undefined)
        $scope.updates[key] += value
      else
        $scope.updates[key] = value

      $scope.updated_total += value

  $scope.resetAbsent = () ->
    return unless ams_data.importSettings['reset_all_absent']
    enterprises_to_reset = []

    angular.forEach $scope.reset_counts, (count, enterprise_id) ->
      enterprises_to_reset.push(enterprise_id)

    if enterprises_to_reset.length && $scope.updated_ids.length
      $http(
        url: ams_data.reset_url
        method: 'POST'
        data:
          'filepath': ams_data.filepath
          'settings': ams_data.importSettings
          'reset_absent': true,
          'updated_ids': $scope.updated_ids,
          'enterprises_to_reset': enterprises_to_reset
      ).then((response) ->
        $scope.updates.products_reset = response.data
      ).catch((response) ->
        console.error(response.data)
      )

  $scope.updateProgress = () ->
    $scope.completed++
    $scope.percentage[$scope.step] = String(Math.round(($scope.completed / $scope.chunks) * 100)) + '%'

    if $scope.completed == $scope.chunks
      $timeout($scope.viewResults, 1000) if $scope.step == 'import'
      $timeout($scope.finalResults, 1000) if $scope.step == 'save'

      $scope.resetAbsent() if $scope.step == 'save'
