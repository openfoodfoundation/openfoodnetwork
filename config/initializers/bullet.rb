# frozen_string_literal: true

if defined?(Bullet) && ENV.fetch("ENABLE_BULLET", false)
  Rails.application.config.after_initialize do
    Bullet.enable = true
    Bullet.add_footer = true
    Bullet.bullet_logger = true
    Bullet.rails_logger = true
  end
end
