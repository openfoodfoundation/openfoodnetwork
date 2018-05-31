module.exports = function(config) {
  config.set({
    basePath: '../',

    frameworks: ['jasmine'],

    files: [
      APPLICATION_SPEC,
      'app/assets/javascripts/shared/jquery-1.8.0.js', // TODO: Can we link to Rails' jquery?
      'app/assets/javascripts/shared/jquery.timeago.js',
      'app/assets/javascripts/shared/angular-local-storage.js',
      'app/assets/javascripts/shared/ng-infinite-scroll.min.js',
      'app/assets/javascripts/shared/angular-slideables.js',

      'app/assets/javascripts/admin/*.js*',
      'app/assets/javascripts/admin/*/*.js*', // Pull in top level files in each folder first (often these are module declarations)
      'app/assets/javascripts/admin/**/*.js*',
      'app/assets/javascripts/darkswarm/*.js*',
      'app/assets/javascripts/darkswarm/**/*.js*',
      'spec/javascripts/unit/**/*.js*'
    ],

    exclude: [
      '**/.#*',
      'app/assets/javascripts/darkswarm/all.js.coffee',
      'app/assets/javascripts/darkswarm/overrides.js.coffee',
      'app/assets/javascripts/darkswarm/i18n.js.erb',
      'app/assets/javascripts/admin/util.js.erb'
    ],

    preprocessors: {
      '**/*.coffee': ['coffee']
    },

    coffeePreprocessor: {
      options: {
        sourceMap: true
      },
      transformPath: function(path) {
        return path.replace(/\.coffee$/, '.js');
      }
    },

    autoWatch: true,

    browsers: ['ChromeHeadless'],

    junitReporter: {
      outputFile: 'log/testacular-unit.xml',
      suite: 'unit'
    }
  });
};
