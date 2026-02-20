# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.2"

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# css and js files other than application.* are not precompiled by default
# Instead, they must be explicitly included below
# http://stackoverflow.com/questions/8012434/what-is-the-purpose-of-config-assets-precompile
Rails.application.config.assets.precompile += [
  'admin/*.js', 'admin/**/*.js', 'admin_minimal.js',
  'web/all.js',
  'darkswarm/all.js',
  'shared/*',
  '*.jpg', '*.jpeg', '*.png', '*.gif' '*.svg',
]
