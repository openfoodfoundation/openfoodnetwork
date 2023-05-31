angular.module("admin.utils").factory "StatusMessage", ->
  new class StatusMessage
    types:
      progress: {style: {color: '#ff9906'}}
      alert:    {style: {color: 'grey'}}
      notice:   {style: {color: 'grey'}}
      success:  {style: {color: '#9fc820'}}
      failure:  {style: {color: '#C85136'}}
      error:   {style: {color: '#C85136'}}

    statusMessage:
      text: ""
      style: {}

    invalidMessage: ""

    setValidation: (isValid) ->
      if isValid
        StatusMessage.invalidMessage = ''
      else
        StatusMessage.invalidMessage = t("admin.form_invalid")

    active: ->
      @statusMessage.text != ''

    display: (type, text) ->
      @statusMessage.text = text
      @statusMessage.style = @types[type].style
      null

    clear: ->
      @statusMessage.text = ''
      @statusMessage.style = {}
