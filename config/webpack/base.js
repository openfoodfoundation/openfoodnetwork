const { webpackConfig } = require('@rails/webpacker')

module.exports = webpackConfig

// TODO try removing this
function addQuietDepsToSassLoader (subloader) {
  if (subloader.loader === 'sass-loader') {
    subloader.options.sassOptions = {
      ...subloader.options.sassOptions,
      quietDeps: true
    }
  }
}

//webpackConfig.loaders.keys().forEach(loaderName => {
//  const loader = webpackConfig.loaders.get(loaderName);
//  if (loaderName === 'sass') {
//    loader.use.forEach(addQuietDepsToSassLoader);
//  }
//  loader.use.forEach(hotfixPostcssLoaderConfig);
//});
