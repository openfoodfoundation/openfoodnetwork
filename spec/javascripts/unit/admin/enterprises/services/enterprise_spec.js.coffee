describe "Enterprise service", ->
  Enterprise = null
  enterprise = { name: "test ent name" }
  beforeEach ->
    module 'admin.enterprises'
    module ($provide) ->
      $provide.value 'enterprise', enterprise
      null

    inject ($injector) ->
      Enterprise = $injector.get("Enterprise")

  it "stores enterprise value as Enterprise.enterprise", ->
    expect(Enterprise.enterprise).toBe enterprise
