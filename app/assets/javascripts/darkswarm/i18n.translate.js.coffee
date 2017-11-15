# Declares the translation function t.
# You can use translate('login') or t('login') in Javascript.
window.translate = (key, options = {}) ->
  unless 'I18n' of window
    console.log 'The I18n object is undefined. Cannot translate text.'
    return key
  I18n.t(key, options)
window.t = window.translate
