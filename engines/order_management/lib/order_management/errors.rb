# frozen_string_literal: true

module OrderManagement
  module Errors
    class Base < StandardError; end
    class ReportNotFound < Base; end
    class MissingQueryParams < Base; end
  end
end
