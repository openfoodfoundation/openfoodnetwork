process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')

const config = environment.toWebpackConfig();
config.output.filename = "js/[name]-[hash].js";

module.exports = config;
