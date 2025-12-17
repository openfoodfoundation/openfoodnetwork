module.exports = {
  plugins: [
    require('postcss-import')({
      // Wepacker isn't passing the configured path to Postcss, so we specify the base path here
      path: process.cwd()
    }),
    require('postcss-flexbugs-fixes'),
    require('postcss-preset-env')({
      autoprefixer: {
        flexbox: 'no-2009'
      },
      stage: 3
    })
  ]
}
