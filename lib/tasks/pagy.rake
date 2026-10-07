# frozen_string_literal: true

# Copy pagy's JavaScript from the gem, so webpack can bundle it.
# Run `bundle exec rake pagy:sync:javascript` after upgrading pagy.
Pagy::SyncTask.new(:javascript, Rails.root.join("app/webpacker/js"), "pagy.mjs")
