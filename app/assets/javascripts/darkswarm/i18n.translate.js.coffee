# Declares the translation function t.
# You can use translate('login') or t('login') in Javascript.
window.translate = (key, options = {}) ->
  unless 'I18n' of window
    console.log 'The I18n object is undefined. Cannot translate text.'
    return key
  dict = I18n
  parts = key.split '.'
  while (parts.length)
    part = parts.shift()
    return key unless part of dict
    dict = dict[part]
  text = dict
  for name, value of options
    text = text.split("%{#{name}}").join(value)
  text
window.t = window.translate
