# Foreman Procfile. Start all dev server processes with: `foreman start`

rails:      bundle exec rails s -p 3000
sidekiq:    bundle exec sidekiq -q mailers -q default
js:         yarn build --watch
