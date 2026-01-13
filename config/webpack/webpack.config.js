const { generateWebpackConfig, merge } = require("shakapacker")

const webpackConfig = generateWebpackConfig()

const options = {
  resolve: {
    extensions: [".mjs", ".js", ".sass",".scss", ".css", ".module.sass", ".module.scss", ".module.css", ".png", ".svg", ".gif", ".jpeg", ".jpg", ".eot", ".ttf", ".woff"]
  }
}

const OFNwebpackConfig = merge(webpackConfig, options) 

// quiet deprecations in dependencies, notably foundation-sites 
const scssRule = OFNwebpackConfig.module.rules.find((rule) => rule.test.test(".scss"))
const sassDefaultOptions = scssRule.use[3].options.sassOptions
scssRule.use[3].options.sassOptions = {
  ...sassDefaultOptions,
  quietDeps: true
}

// This results in a new object copied from the mutable global
module.exports = OFNwebpackConfig
