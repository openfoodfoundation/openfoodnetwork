# frozen_string_literal: true

module Reports
  module Renderers
    class Base
      attr_reader :report_data

      def initialize(report_data)
        @report_data = report_data
      end
    end
  end
end
