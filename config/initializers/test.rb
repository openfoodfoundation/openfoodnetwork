# frozen_string_literal: true

I18n.exception_handler = Proc.new do |exception, *_|
  raise exception.to_exception
end