# frozen_string_literal: true

# Whether fields, links, and buttons will match against aria-label attribute.
# This allows us to find <input aria-label="Name"> with `expect(page).to have_field "Name"`
Capybara.enable_aria_label = true

# The default wait time is 2 seconds. Small is good for test-driven development
# ensuring efficient code but some machines can be a bit slow.
# And we want to avoid flakiness.
Capybara.default_max_wait_time = ENV.fetch("CAPYBARA_MAX_WAIT_TIME").to_i

# Normalize whitespaces when using `has_text?` and similar matchers,
# i.e., ignore newlines, trailing spaces, etc.
# That makes tests less dependent on slightly UI changes.
Capybara.default_normalize_ws = true

# Where to store system tests artifacts (e.g. screenshots, downloaded files, etc.).
# It could be useful to be able to configure this path from the outside (e.g., on CI).
Capybara.save_path = ENV.fetch("CAPYBARA_ARTIFACTS", "./tmp/capybara")

Capybara.singleton_class.prepend(Module.new do
  attr_accessor :last_used_session

  def using_session(name, &)
    self.last_used_session = name
    super
  ensure
    self.last_used_session = nil
  end
end)
