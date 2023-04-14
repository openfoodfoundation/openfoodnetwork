const { environment } = require('@rails/webpacker')

module.exports = environment

function hotfixPostcssLoaderConfig (subloader) {
  const subloaderName = subloader.loader
  if (subloaderName === 'postcss-loader') {
    if (subloader.options.postcssOptions) {
      console.log(
        '\x1b[31m%s\x1b[0m',
        'Remove postcssOptions workaround in config/webpack/environment.js'
      )
    } else {
      subloader.options.postcssOptions = subloader.options.config;
      delete subloader.options.config;
    }
  }
}

function addQuietDepsToSassLoader (subloader) {
  if (subloader.loader === 'sass-loader') {
    subloader.options.sassOptions = {
      ...subloader.options.sassOptions,
      quietDeps: true
    }
  }
}

environment.loaders.keys().forEach(loaderName => {
  const loader = environment.loaders.get(loaderName);
  if (loaderName === 'sass') {
    loader.use.forEach(addQuietDepsToSassLoader);
  }
  loader.use.forEach(hotfixPostcssLoaderConfig);
});
