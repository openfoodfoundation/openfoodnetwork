# frozen_string_literal: true

module Admin
  class EnterpriseRolesQuery
    class << self
      def query
        enterprise_roles = query_enterprise_roles
        users = query_users
        enterprises = query_enterprises

        [enterprise_roles, users, enterprises]
      end

      private

      def query_enterprise_roles
        EnterpriseRole.joins(:user, :enterprise).order('spree_users.email ASC').
          pluck(:id, :user_id, :enterprise_id, 'spree_users.email', 'enterprises.name').
          map do |data|
            id, user_id, enterprise_id, user_email, enterprise_name = data

            { id:, user_id:, enterprise_id:, user_email:, enterprise_name: }
          end
      end

      def query_users
        Spree::User.order(:email).pluck(:id, :email).map do |data|
          id, email = data

          { id:, email: }
        end
      end

      def query_enterprises
        Enterprise.order(:name).pluck(:id, :name).map do |data|
          id, name = data

          { id:, name: }
        end
      end
    end
  end
end
