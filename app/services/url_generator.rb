# frozen_string_literal: false

# Converts strings for use as parts of a URL. The input can contain non-roman/non-UTF8 characters
# and the output will still be valid (including some transliteration). Examples:
#
# "Top Cat!"   -> "top-cat"
# "Père Noël"  -> "pere-noel"
# "你好"        -> "ni-hao"

require "stringex/unidecoder"

class UrlGenerator
  def self.to_url(string)
    Stringex::Unidecoder.decode(string.to_s).parameterize
  end
end
