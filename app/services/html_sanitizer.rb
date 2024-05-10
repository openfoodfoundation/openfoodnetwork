# frozen_string_literal: true

# Keeps only allowed HTML.
#
# We store some rich text as HTML in attributes of models like Enterprise.
# We offer an editor which supports certain tags but you can't insert just any
# HTML, which would be dangerous.
class HtmlSanitizer
  def self.sanitize(*args)
    @sanitizer ||= Rails::HTML5::SafeListSanitizer.new
    @sanitizer.sanitize(*args)
  end
end
