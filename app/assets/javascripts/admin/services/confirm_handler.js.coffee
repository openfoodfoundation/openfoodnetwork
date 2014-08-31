angular.module("ofn.admin").factory "ofnConfirmHandler", (pendingChanges, $compile, $q) ->
  return (scope, callback) ->
    template = "<div id='dialog-div' style='padding: 10px'><h6>Unsaved changes currently exist, save now or ignore?</h6></div>"
    dialogDiv = $compile(template)(scope)
    return ->
      if pendingChanges.changeCount(pendingChanges.pendingChanges) > 0
        dialogDiv.dialog
          dialogClass: "no-close"
          resizable: false
          height: 140
          modal: true
          buttons:
            "SAVE": ->
              dialogDiv = $(this)
              $q.all(pendingChanges.submitAll()).then ->
                callback()
                dialogDiv.dialog "close"
            "IGNORE": ->
              callback()
              $(this).dialog "close"
              scope.$apply()
        dialogDiv.dialog "open"
      else
        callback()