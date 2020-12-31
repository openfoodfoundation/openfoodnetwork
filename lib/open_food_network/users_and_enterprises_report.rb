module OpenFoodNetwork
  class UsersAndEnterprisesReport
    attr_reader :params
    def initialize(params = {}, compile_table = false)
      @params = params
      @compile_table = compile_table

      # Convert arrays of ids to comma delimited strings
      if @params[:enterprise_id_in].is_a? Array
        @params[:enterprise_id_in] = @params[:enterprise_id_in].join(',')
      end
      @params[:user_id_in] = @params[:user_id_in].join(',') if @params[:user_id_in].is_a? Array
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
      query = Enterprise.joins("LEFT JOIN spree_users AS owner ON enterprises.owner_id = owner.id")
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
        .select(["enterprises.name",
                 "enterprises.sells",
                 "enterprises.visible",
                 "enterprises.is_primary_producer",
                 "enterprises.created_at",
                 "#{email_user}.email AS user_email"])
        .to_a
        .map { |x|
        {
          name: x.name,
          sells: x.sells,
          visible: (x.visible ? 't' : 'f'),
          is_primary_producer: (x.is_primary_producer ? 't' : 'f'),
          created_at: x.created_at.utc.iso8601,
          relationship_type: relationship_type,
          user_email: x.user_email
        }.stringify_keys
      }
    end

    def users_and_enterprises
      sort( owners_and_enterprises.concat(managers_and_enterprises) )
    end

    def filter_by_int_list_if_present(query, filtered_field_name, int_list)
      if int_list.present?
        query = query.where("#{filtered_field_name} IN (?)", split_int_list(int_list))
      end
      query
    end

    def split_int_list(int_list)
      int_list.split(',').map(&:to_i)
    end

    def sort(results)
      results.sort do |a, b|
        if a["created_at"].nil? || b["created_at"].nil?
          [(a["created_at"].nil? ? 0 : 1), a["name"], b["relationship_type"], a["user_email"]] <=>
            [(b["created_at"].nil? ? 0 : 1), b["name"], a["relationship_type"], b["user_email"]]
        else
          [
            DateTime.parse(b["created_at"]).in_time_zone,
            a["name"],
            b["relationship_type"],
            a["user_email"]
          ] <=> [
            DateTime.parse(a["created_at"]).in_time_zone,
            b["name"],
            a["relationship_type"],
            b["user_email"]
          ]
        end
      end
    end

    def to_bool(value)
      ActiveRecord::Type::Boolean.new.type_cast_from_database(value)
    end

    def to_local_datetime(date)
      return "" if date.nil?

      date.to_datetime.in_time_zone.strftime "%Y-%m-%d %H:%M"
    end
  end
end
