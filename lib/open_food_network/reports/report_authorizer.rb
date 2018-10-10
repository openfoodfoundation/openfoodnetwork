module OpenFoodNetwork
  module Reports
    class ReportAuthorizer
      attr_accessor :user

      def initialize(user)
        @user = user
      end
    end
  end
end
