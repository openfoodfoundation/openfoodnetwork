# frozen_string_literal: false

# Formats uploaded files to UTF-8 encoding and strips unexpected BOM characters.
# Takes an open File object as input
class UploadSanitizer
  def initialize(upload)
    @data = upload
  end

  def call
    @data.force_encoding('UTF-8')
    strip_bom_character
  end

  private

  def strip_bom_character
    @data.scrub.gsub("\xEF\xBB\xBF".force_encoding("UTF-8"), '')
  end
end
