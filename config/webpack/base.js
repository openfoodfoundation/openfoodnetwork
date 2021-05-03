const { webpackConfig } = require('@rails/webpacker');
const { merge } = require('webpack-merge')  ;

const customConfig = {
  resolve: {
    extensions: ['.css']
  }
}
module.exports = merge(webpackConfig, customConfig)
