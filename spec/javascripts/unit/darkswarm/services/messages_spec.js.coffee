describe 'Messages service', ->
  Messages = null
  Loading = null
  RailsFlashLoader = null

  beforeEach ->
    module 'Darkswarm'

    module ($provide)->
      $provide.value "railsFlash", null
      null

    inject (_Messages_, _Loading_, _RailsFlashLoader_)->
      Messages = _Messages_
      Loading = _Loading_
      RailsFlashLoader = _RailsFlashLoader_

  it "shows a loading message", ->
    Messages.loading("Hang on...")
    expect(Loading.message).toEqual "Hang on..."

  it "shows a success message", ->
    spyOn(RailsFlashLoader, "loadFlash")
    Messages.success("Yay!")
    expect(RailsFlashLoader.loadFlash).toHaveBeenCalledWith({success: "Yay!"})

  it "shows a error message", ->
    spyOn(RailsFlashLoader, "loadFlash")
    Messages.error("Boo!")
    expect(RailsFlashLoader.loadFlash).toHaveBeenCalledWith({error: "Boo!"})

  it "shows a flash message", ->
    data = {info: "thinking"}
    spyOn(RailsFlashLoader, "loadFlash")
    Messages.flash(data)
    expect(RailsFlashLoader.loadFlash).toHaveBeenCalledWith(data)

  it "clears a loading message", ->
    Messages.loading("Hang on...")
    Messages.success("Done.")
    expect(Loading.message).toEqual null
