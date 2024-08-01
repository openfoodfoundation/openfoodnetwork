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
      style: {},
      type: null,
      actionName: null

    invalidMessage: ""

    setValidation: (isValid) ->
      if isValid
        StatusMessage.invalidMessage = ''
      else
        StatusMessage.invalidMessage = t("admin.form_invalid")

    active: ->
      @statusMessage.text != ''

    display: (type, text, actionName = null) ->
      @statusMessage.text = text
      @statusMessage.type = type
      @statusMessage.actionName = actionName
      @statusMessage.style = @types[type].style
      null

    clear: ->
      @statusMessage.text = ''
      @statusMessage.style = {}
      @statusMessage.type = null
      @statusMessage.actionName = null
