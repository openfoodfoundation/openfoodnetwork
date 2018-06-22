module OpenFoodNetwork
  class UsersAndEnterprisesReport
    attr_reader :params
    def initialize(params = {}, compile_table = false)
      @params = params
      @compile_table = compile_table

      # Convert arrays of ids to comma delimited strings
      @params[:enterprise_id_in] = @params[:enterprise_id_in].join(',') if @params[:enterprise_id_in].kind_of? Array
      @params[:user_id_in] = @params[:user_id_in].join(',') if @params[:user_id_in].kind_of? Array
    end

    def header
      [
        I18n.t(:report_header_user),
        I18n.t(:report_header_relationship),
        I18n.t(:report_header_enterprise),
        I18n.t(:report_header_is_producer),
        I18n.t(:report_header_sells),
        I18n.t(:report_header_visible),
        I18n.t(:report_header_confirmation_date),
      ]
    end

    def table
      return [] unless @compile_table
      users_and_enterprises.map do |uae|
        [
          uae["user_email"],
          uae["relationship_type"],
          uae["name"],
          to_bool(uae["is_primary_producer"]),
          uae["sells"],
          uae["visible"],
          to_local_datetime(uae["created_at"])
        ]
      end
    end

    def owners_and_enterprises
      query = "SELECT enterprises.name, enterprises.sells, enterprises.visible, enterprises.is_primary_producer, enterprises.created_at AS created_at,
      'owns' AS relationship_type, owners.email as user_email FROM enterprises
      LEFT JOIN spree_users AS owners ON owners.id=enterprises.owner_id
      WHERE enterprises.id IS NOT NULL
      #{ params[:enterprise_id_in].present? ? "AND enterprises.id IN (#{ params[:enterprise_id_in] })" : "" }
      #{ params[:user_id_in].present? ? "AND owners.id IN (#{ params[:user_id_in] })" : "" }
      ORDER BY enterprises.created_at DESC"

      ActiveRecord::Base.connection.execute(query).to_a
    end

    def managers_and_enterprises
      query = "SELECT enterprises.name, enterprises.sells, enterprises.visible, enterprises.is_primary_producer, enterprises.created_at AS created_at,
      'manages' AS relationship_type, managers.email as user_email FROM enterprises
      LEFT JOIN enterprise_roles ON enterprises.id=enterprise_roles.enterprise_id
      LEFT JOIN spree_users AS managers ON enterprise_roles.user_id=managers.id
      WHERE enterprise_id IS NOT NULL
      #{ params[:enterprise_id_in].present? ? "AND enterprise_id IN (#{ params[:enterprise_id_in] })" : "" }
      AND user_id IS NOT NULL
      #{ params[:user_id_in].present? ? "AND user_id IN (#{ params[:user_id_in] })" : "" }
      ORDER BY enterprises.created_at DESC"

      ActiveRecord::Base.connection.execute(query).to_a
    end

    def users_and_enterprises
      sort( owners_and_enterprises.concat managers_and_enterprises )
    end

    def sort(results)
      results.sort do |a,b|
        if a["created_at"].nil? || b["created_at"].nil?
          [ (a["created_at"].nil? ? 0 : 1), a["name"], b["relationship_type"], a["user_email"] ] <=>
          [ (b["created_at"].nil? ? 0 : 1), b["name"], a["relationship_type"], b["user_email"] ]
        else
          [ DateTime.parse(b["created_at"]), a["name"], b["relationship_type"], a["user_email"] ] <=>
          [ DateTime.parse(a["created_at"]), b["name"], a["relationship_type"], b["user_email"] ]
        end
      end
    end

    def to_bool(value)
      ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
    end

    def to_local_datetime(date)
      return "" if date.nil?
      date.to_datetime.in_time_zone.strftime "%Y-%m-%d %H:%M"
    end
  end
end
