const { webpackConfig } = require('@rails/webpacker')

module.exports = webpackConfig

// TODO see if we can remove
function hotfixPostcssLoaderConfig (subloader) {
  const subloaderName = subloader.loader
  if (subloaderName === 'postcss-loader') {
    if (subloader.options.postcssOptions) {
      console.log(
        '\x1b[31m%s\x1b[0m',
        'Remove postcssOptions workaround in config/webpack/base.js'
      )
    } else {
      subloader.options.postcssOptions = subloader.options.config;
      delete subloader.options.config;
    }
  }
}

// TODO try removing this
function addQuietDepsToSassLoader (subloader) {
  if (subloader.loader === 'sass-loader') {
    subloader.options.sassOptions = {
      ...subloader.options.sassOptions,
      quietDeps: true
    }
  }
}

webpackConfig.loaders.keys().forEach(loaderName => {
  const loader = webpackConfig.loaders.get(loaderName);
  if (loaderName === 'sass') {
    loader.use.forEach(addQuietDepsToSassLoader);
  }
  loader.use.forEach(hotfixPostcssLoaderConfig);
});

