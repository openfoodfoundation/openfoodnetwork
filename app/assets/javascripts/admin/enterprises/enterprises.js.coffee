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
.config [
  '$provide', ($provide) ->
    $provide.decorator 'taTranslations', [
      '$delegate'
      (taTranslations) ->
        taTranslations.insertLink = {
          tooltip: 'Insert / edit link',
          dialogPrompt: "Please enter a URL to insert"
        }
        taTranslations
    ]
]
