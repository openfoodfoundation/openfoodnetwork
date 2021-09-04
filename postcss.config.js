const environment = {
  plugins: [
    require('postcss-import'),
    require('tailwindcss'),
    require('autoprefixer'),
    require('postcss-flexbugs-fixes'),
    require('postcss-preset-env')({
      autoprefixer: {
        flexbox: 'no-2009'
      },
      stage: 3
    })
  ]
}

if (process.env.RAILS_ENV === "production" || process.env.RAILS_ENV === "staging") {
  environment.plugins.push(
      require('@fullhuman/postcss-purgecss')({
        content: [
          "./app/views/**/*.html.erb",
          "./app/views/**/*.html.haml",
          "./app/assets/javascript/templates/**/*.html.haml",
          "./engines/**/*.html.haml",
        ],
        defaultExtractor: content => content.match(/[A-Za-z0-9-_:/]+/g) || []
      })
  )
}

module.exports = environment
