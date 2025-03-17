# Foreman Procfile. Start all dev server processes with: `foreman start`

rails:      DEV_CACHING=true bundle exec rails s -p 3000
webpack:    ./bin/webpack-dev-server
sidekiq:    DEV_CACHING=true bundle exec sidekiq -q mailers -q default
