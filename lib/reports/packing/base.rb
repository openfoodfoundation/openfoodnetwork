# frozen_string_literal: true

module Reports
  module Packing
    class Base < ReportTemplate
      SUBTYPES = ["customer", "supplier"]



      private

      def i18n_scope
        "admin.reports"
      end
    end
  end
end
