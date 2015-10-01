# Declares the translation function t.
# You can use t('login') in Javascript.
window.t = (key, options = {}) ->
  unless 'I18n' of window
    console.log 'The I18n object is undefined. Cannot translate text.'
    return key
  return key unless key of I18n
  text = I18n[key]
  for name, value of options
    text = text.split("%{#{name}}").join(value)
  text

# Provides the translation function t on all scopes.
# You can write {{t('login')}} in all templates.
window.Darkswarm.run ($rootScope) ->
  $rootScope.t = t
