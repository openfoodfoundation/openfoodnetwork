# frozen_string_literal: true

RSpec::Matchers.define :have_flash_message do |message|
  match do |node|
    @message, @node = message, node

    # Ignore leading and trailing whitespace. Later versions of Capybara have :exact_text option.
    # The :exact option is not supported in has_selector?.
    message_substring_regex = substring_match_regex(message)
    node.has_selector?(".flash", text: message_substring_regex, visible: false)
  end

  failure_message do |_actual|
    "expected to find flash message ##{@message}"
  end

  match_when_negated do |node|
    @message, @node = message, node

    # Ignore leading and trailing whitespace. Later versions of Capybara have :exact_text option.
    # The :exact option is not supported in has_selector?.
    message_substring_regex = substring_match_regex(message)
    node.has_no_selector?(".flash", text: message_substring_regex, visible: false)
  end

  failure_message_when_negated do |_actual|
    "expected not to find flash message ##{@message}"
  end

  def substring_match_regex(text)
    /\A\s*#{Regexp.escape(text)}\s*\Z/
  end
end
