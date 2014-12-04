angular.module("ofn.admin").factory "StatusMessage", ($timeout) ->
  new class StatusMessage
    types:
      progress: {timeout: false, style: {color: '#ff9906'}}
      alert:    {timeout: 3000,  style: {color: 'grey'}}
      notice:   {timeout: false, style: {color: 'grey'}}
      success:  {timeout: 3000,  style: {color: '#9fc820'}}
      failure:  {timeout: false, style: {color: '#da5354'}}

    statusMessage:
      text: ""
      style: {}

    displayMessage: (text, type) ->
      @statusMessage.text = text
      @statusMessage.style = @types[type].style
      $timeout.cancel @statusMessage.timeout  if @statusMessage.timeout
      timeout = @types[type].timeout
      if timeout
        @statusMessage.timeout = $timeout =>
          @clearMessage()
        , timeout, true

    clearMessage: ->
      @statusMessage.text = ''
      @statusMessage.style = {}
