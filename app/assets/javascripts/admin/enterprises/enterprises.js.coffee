angular.module("admin.enterprises", [
  "admin.paymentMethods",
  "admin.utils",
  "admin.shippingMethods",
  "admin.users",
  "textAngular",
  "admin.side_menu",
  "admin.taxons",
  'admin.indexUtils',
  'admin.tagRules',
  'admin.dropdown',
  'ngSanitize']
)
# For more options: https://github.com/textAngular/textAngular/blob/master/src/textAngularSetup.js
.config [
  '$provide', ($provide) ->
    $provide.decorator 'taTranslations', [
      '$delegate'
      (taTranslations) ->
        taTranslations.insertLink = {
          tooltip: t('admin.enterprises.form.shop_preferences.shopfront_message_link_tooltip'),
          dialogPrompt: t('admin.enterprises.form.shop_preferences.shopfront_message_link_prompt')
        }
        taTranslations
    ]
]
