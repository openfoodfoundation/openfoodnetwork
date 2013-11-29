basePath = '../';

files = [
  JASMINE,
  JASMINE_ADAPTER,
  'app/assets/javascripts/shared/jquery-1.8.0.js', // TODO: Can we link to Rails' jquery?
  'app/assets/javascripts/shared/angular.js',
  'app/assets/javascripts/shared/angular-*.js',

  'app/assets/javascripts/admin/order_cycle.js.erb.coffee',
  'app/assets/javascripts/admin/bulk_product_update.js.coffee',

  'spec/javascripts/unit/**/*.js*'
];

exclude = ['**/.#*']

autoWatch = true;

browsers = ['Chrome'];

junitReporter = {
  outputFile: 'log/testacular-unit.xml',
  suite: 'unit'
};
