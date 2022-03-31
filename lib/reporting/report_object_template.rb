# frozen_string_literal: true

# This is the old way of managing report, by loading Models from the DB and building
# The result from those models
module Reporting
  class ReportObjectTemplate < ReportTemplate

    def table_headers
      raise NotImplementedError
    end

    def table_rows
      raise NotImplementedError
    end

    # Rules for grouping, ordering, and summary rows
    def rules
      []
    end
  end
end
