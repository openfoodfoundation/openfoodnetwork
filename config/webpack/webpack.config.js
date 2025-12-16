const { generateWebpackConfig } = require("@rails/webpacker")

const options = {
  resolve: {
    extensions: [".mjs", ".js", ".sass",".scss", ".css", ".module.sass", ".module.scss", ".module.css", ".png", ".svg", ".gif", ".jpeg", ".jpg", ".eot", ".ttf", ".woff"]
  }
}

// This results in a new object copied from the mutable global
module.exports = generateWebpackConfig(options)
