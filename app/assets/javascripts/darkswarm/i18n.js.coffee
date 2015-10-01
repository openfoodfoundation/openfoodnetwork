# Declares the translation function t.
# You can use t('login') in Javascript.
window.t = (key, options = {}) ->
  if I18n == undefined
    console.log 'The I18n object is undefined. Cannot translate text.'
    return key
  text = I18n[key]
  return key if text == undefined
  text = text.split("%{#{name}}").join(value) for name, value of options
  text

# Provides the translation function t on all scopes.
# You can write {{t('login')}} in all templates.
window.Darkswarm.run ($rootScope) ->
  $rootScope.t = t
