module OpenFoodNetwork
  module Reports
    module Renderers
      class Base
        attr_accessor :report_data

        def initialize(report_data)
          @report_data = report_data
        end
      end
    end
  end
end
