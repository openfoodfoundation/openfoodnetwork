const { webpackConfig, merge } = require('@rails/webpacker')

const extensions = {
  resolve: {
    extensions: [".mjs",".js",".sass",".scss",".css",".module.sass,",".module.scss,",".module.css",".png",".svg",".gif",".jpeg",".jpg",".eot",".ttf",".woff"]
  }
}

module.exports = merge( webpackConfig, extensions)
