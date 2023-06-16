# frozen_string_literal: true

module Reporting
  module Reports
    module UsersAndEnterprises
      class Base < ReportTemplate
        def query_result
          sort(owners_and_enterprises.concat(managers_and_enterprises))
        end

        def columns
          {
            user: proc { |x| x.user_email },
            relationship: proc { |x| x.relationship_type },
            enterprise: proc { |x| x.name },
            is_producer: proc { |x| x.is_primary_producer },
            sells: proc { |x| x.sells },
            visible: proc { |x| x.visible },
            confirmation_date: proc { |x| x.created_at },
            ofn_uid: proc { |x| x.ofn_uid }
          }
        end

        def owners_and_enterprises
          query = Enterprise
            .joins("LEFT JOIN spree_users AS owner ON enterprises.owner_id = owner.id")
            .where("enterprises.id IS NOT NULL")

          query = filter_by_int_list_if_present(query, "enterprises.id", params[:enterprise_id_in])
          query = filter_by_int_list_if_present(query, "owner.id", params[:user_id_in])

          query_helper(query, :owner, :owns)
        end

        def managers_and_enterprises
          query = Enterprise
            .joins("LEFT JOIN enterprise_roles ON enterprises.id = enterprise_roles.enterprise_id")
            .joins("LEFT JOIN spree_users AS managers ON enterprise_roles.user_id = managers.id")
            .where("enterprise_id IS NOT NULL")
            .where("user_id IS NOT NULL")

          query = filter_by_int_list_if_present(query, "enterprise_id", params[:enterprise_id_in])
          query = filter_by_int_list_if_present(query, "user_id", params[:user_id_in])

          query_helper(query, :managers, :manages)
        end

        def query_helper(query, email_user, relationship_type)
          query.order("enterprises.created_at DESC")
            .select(["enterprises.id AS ofn_uid",
                     "enterprises.name",
                     "enterprises.sells",
                     "enterprises.visible",
                     "enterprises.is_primary_producer",
                     "enterprises.created_at",
                     "#{email_user}.email AS user_email",
                     "'#{relationship_type}' AS relationship_type"])
            .to_a
        end

        def filter_by_int_list_if_present(query, filtered_field_name, int_list)
          if int_list.present?
            query = query.where("#{filtered_field_name} IN (?)", int_list.map(&:to_i))
          end
          query
        end

        def sort(results)
          results.sort do |a, b|
            a_date = (a.created_at || Date.new(1970, 1, 1)).in_time_zone
            b_date = (b.created_at || Date.new(1970, 1, 1)).in_time_zone
            [b_date, a.name, b.relationship_type, a.user_email] <=>
              [a_date, b.name, a.relationship_type, b.user_email]
          end
        end
      end
    end
  end
end
