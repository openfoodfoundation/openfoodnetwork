angular.module("ofn.admin").factory "StatusMessage", ($timeout) ->
  new class StatusMessage
    types:
      progress: {timeout: false, style: {color: '#ff9906'}}
      alert:    {timeout: 5000,  style: {color: 'grey'}}
      notice:   {timeout: false, style: {color: 'grey'}}
      success:  {timeout: 5000,  style: {color: '#9fc820'}}
      failure:  {timeout: false, style: {color: '#da5354'}}

    statusMessage:
      text: ""
      style: {}

    display: (type, text) ->
      @statusMessage.text = text
      @statusMessage.style = @types[type].style
      $timeout.cancel @statusMessage.timeout  if @statusMessage.timeout
      timeout = @types[type].timeout
      if timeout
        @statusMessage.timeout = $timeout =>
          @clear()
        , timeout, true

    clear: ->
      @statusMessage.text = ''
      @statusMessage.style = {}
