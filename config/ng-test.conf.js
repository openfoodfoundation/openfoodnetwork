module.exports = function(config) {
  config.set({
    basePath: '../',

    frameworks: ['jasmine'],

    files: [
      APPLICATION_SPEC,
      'app/assets/javascripts/shared/angular-local-storage.js',
      'app/assets/javascripts/shared/ng-infinite-scroll.min.js',
      'app/assets/javascripts/shared/angular-slideables.js',

      'app/assets/javascripts/admin/*.js*',
      'app/assets/javascripts/admin/*/*.js*', // Pull in top level files in each folder first (often these are module declarations)
      'app/assets/javascripts/admin/**/*.js*',
      'app/assets/javascripts/darkswarm/*.js*',
      'app/assets/javascripts/darkswarm/**/*.js*',
      'app/assets/javascripts/shared/shared.js.coffee',
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
    browsers: ['CustomHeadlessChrome'],
    customLaunchers: {
      CustomHeadlessChrome: {
        base: 'ChromeHeadless',
        flags: [
          '--no-sandbox',
          '--remote-debugging-port=9222',
          '--enable-logging',
          '--disable-background-timer-throttling',
          '--disable-renderer-backgrounding',
          '--proxy-bypass-list=*',
          '--proxy-server=\'direct://\''
       ]
      }
    },

    junitReporter: {
      outputFile: 'log/testacular-unit.xml',
      suite: 'unit'
    }
  });
};
