// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//

// jquery and angular
//= require jquery2
//= require jquery.ui.all
//= require jquery.powertip
//= require jquery.cookie
//= require jquery.jstree/jquery.jstree
//= require jquery.vAlign
//= require angular
//= require angular-resource
//= require angular-animate
//= require angularjs-file-upload
//= require ../shared/ng-infinite-scroll.min.js
//= require ../shared/ng-tags-input.min.js
//= require angular-rails-templates
//= require lodash.underscore.js

// spree
//= require admin/spree/spree
//= require admin/spree/spree-select2
//= require modernizr
//= require equalize
//= require css_browser_selector_dev
//= require responsive-tables
//= require admin/spree/handlebar_extensions

// OFN specific
//= require ../shared/shared
//= require_tree ../shared/directives
//= require_tree ../templates/shared
//= require_tree ../templates/admin
//= require ./admin_ofn
//= require ./customers/customers
//= require ./dropdown/dropdown
//= require ./enterprises/enterprises
//= require ./enterprise_fees/enterprise_fees
//= require ./enterprise_groups/enterprise_groups
//= require ./index_utils/index_utils
//= require ./inventory_items/inventory_items
//= require ./line_items/line_items
//= require ./orders/orders
//= require ./order_cycles/order_cycles
//= require ./payment_methods/payment_methods
//= require ./payments/payments
//= require ./product_import/product_import
//= require ./products/products
//= require ./resources/resources
//= require ./shipping_methods/shipping_methods
//= require ./side_menu/side_menu
//= require ./subscriptions/subscriptions
//= require ./tag_rules/tag_rules
//= require ./taxons/taxons
//= require ./utils/utils
//= require ./users/users
//= require ./variant_overrides/variant_overrides

// text, dates and translations
//= require textAngular-rangy.min.js
// This replaces angular-sanitize. We should include only one.
// https://github.com/textAngular/textAngular#where-to-get-it
//= require textAngular-sanitize.min.js
//= require textAngular.min.js
//= require i18n/translations
//= require darkswarm/i18n.translate.js

// foundation
//= require ../shared/mm-foundation-tpls-0.9.0-20180826174721.min.js

// LocalStorage
//= require ../shared/angular-local-storage.js

// requires the rest of the JS code in this folder
//= require_tree .
