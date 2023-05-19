# frozen_string_literal: true

class FilePathSanitizer
  def sanitize(file_path, on_error: nil)
    pathname = Pathname.new(file_path)
    return pathname.realpath if pathname.file?

    on_error&.call
    false
  end
end
