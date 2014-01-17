module.exports = function(config) {
  config.set({
    basePath: '../',

    frameworks: ['jasmine'],

    files: [
      'app/assets/javascripts/shared/jquery-1.8.0.js', // TODO: Can we link to Rails' jquery?
      'app/assets/javascripts/shared/angular.js',
      'app/assets/javascripts/shared/angular-*.js',

      'app/assets/javascripts/admin/order_cycle.js.erb.coffee',
      'app/assets/javascripts/admin/bulk_order_management.js.coffee',
      'app/assets/javascripts/admin/bulk_product_update.js.coffee',
      'app/assets/javascripts/darkswarm/*.js*',
      'app/assets/javascripts/darkswarm/**/*.js*',

      'spec/javascripts/unit/**/*.js*'
    ],

    exclude: [
      '**/.#*',
      'app/assets/javascripts/darkswarm/all.js.coffee',
      'app/assets/javascripts/darkswarm/overrides.js.coffee'
    ],

    coffeePreprocessor: {
      options: {
        sourceMap: true
      }
    },

    autoWatch: true,

    browsers: ['Chrome'],

    junitReporter: {
      outputFile: 'log/testacular-unit.xml',
      suite: 'unit'
    }
  });
};
