# Declares the translation function t.
# You can use translate('login') or t('login') in Javascript.
window.translate = (key, options = {}) ->
  unless 'I18n' of window
    console.log 'The I18n object is undefined. Cannot translate text.'
    return key
  return key unless key of I18n
  text = I18n[key]
  for name, value of options
    text = text.split("%{#{name}}").join(value)
  text
window.t = window.translate
