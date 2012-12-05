basePath = '../';

files = [
  JASMINE,
  JASMINE_ADAPTER,
  'app/assets/javascripts/shared/angular.js',
  'app/assets/javascripts/shared/angular-*.js',
  //'test/lib/angular/angular-mocks.js',

  'app/assets/javascripts/admin/order_cycle.js.erb',

  'spec/javascripts/unit/**/*.js*'
];

exclude = ['**/.#*']

autoWatch = true;

browsers = ['Chrome'];

junitReporter = {
  outputFile: 'log/testacular-unit.xml',
  suite: 'unit'
};
