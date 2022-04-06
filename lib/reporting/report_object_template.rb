# frozen_string_literal: true

# This is the old way of managing report, by loading Models from the DB and building
# The result from those models
module Reporting
  class ReportObjectTemplate < ReportTemplate
    # rubocop:disable Rails/Delegate
    # Not delegating for now cause not all subclasses are ready to use reportGrouper
    # so they can implement this method themseves
    def table_rows
      grouper.table_rows
    end
    # rubocop:enable Rails/Delegate

    # The search result, an ActiveRecord Array
    def query_result
      raise NotImplementedError
    end

    # Convert the query_result into expected row result (which will be displayed)
    # Example
    # {
    #   name: proc { |model| model.display_name },
    #   best_friend: proc { |model| model.friends.first.first_name }
    # }
    def columns
      raise NotImplementedError
    end
  end
end
