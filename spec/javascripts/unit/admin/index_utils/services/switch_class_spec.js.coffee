describe "switchClass service", ->
  elementMock = timeoutMock = {}
  removeClass = addClass = switchClassService = null

  beforeEach ->
    addClass = jasmine.createSpy('addClass')
    removeClass = jasmine.createSpy('removeClass')
    elementMock =
      addClass: addClass
      removeClass: removeClass
    timeoutMock = jasmine.createSpy('timeout').and.returnValue "new timeout"
    timeoutMock.cancel = jasmine.createSpy('timeout.cancel')

  beforeEach ->
    module "ofn.admin" , ($provide) ->
      $provide.value '$timeout', timeoutMock
      return

  beforeEach inject (switchClass) ->
    switchClassService = switchClass

  it "calls addClass on the element once", ->
    switchClassService elementMock, "addClass", [], false
    expect(addClass).toHaveBeenCalledWith "addClass"
    expect(addClass.calls.count()).toBe 1

  it "calls removeClass on the element for ", ->
    switchClassService elementMock, "", ["remClass1", "remClass2", "remClass3"], false
    expect(removeClass).toHaveBeenCalledWith "remClass1"
    expect(removeClass).toHaveBeenCalledWith "remClass2"
    expect(removeClass).toHaveBeenCalledWith "remClass3"
    expect(removeClass.calls.count()).toBe 3

  it "call cancel on element.timout only if it exists", ->
    switchClassService elementMock, "", [], false
    expect(timeoutMock.cancel).not.toHaveBeenCalled()
    elementMock.timeout = true
    switchClassService elementMock, "", [], false
    expect(timeoutMock.cancel).toHaveBeenCalled()

  it "doesn't set up a new timeout if 'timeout' is false", ->
    switchClassService elementMock, "class1", ["class2"], false
    expect(timeoutMock).not.toHaveBeenCalled()

  it "doesn't set up a new timeout if 'timeout' is a string", ->
    switchClassService elementMock, "class1", ["class2"], "string"
    expect(timeoutMock).not.toHaveBeenCalled()

  it "sets up a new timeout if 'timeout' parameter is an integer", ->
    switchClassService elementMock, "class1", ["class2"], 1000
    expect(timeoutMock).toHaveBeenCalled()
    expect(elementMock.timeout).toEqual "new timeout"
