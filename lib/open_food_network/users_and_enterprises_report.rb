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
      query = Enterprise.joins("LEFT JOIN spree_users AS owner ON enterprises.owner_id = owner.id")
        .where("enterprises.id IS NOT NULL")

      if params[:enterprise_id_in].present?
        query = query.where("enterprises.id IN (?)",
                            params[:enterprise_id_in].split(',').map(&:to_i))
      end

      if params[:user_id_in].present?
        query = query.where("owner.id IN (?)", params[:user_id_in].split(',').map(&:to_i))
      end

      query.order("enterprises.created_at DESC")
        .select(["enterprises.name",
                 "enterprises.sells",
                 "enterprises.visible",
                 "enterprises.is_primary_producer",
                 "enterprises.created_at",
                 "owner.email AS user_email"])
        .to_a
        .map { |x|
        {
          name: x.name,
          sells: x.sells,
          visible: (x.visible ? 't' : 'f'),
          is_primary_producer: (x.is_primary_producer ? 't' : 'f'),
          created_at: x.created_at.utc.iso8601,
          relationship_type: 'owns',
          user_email: x.user_email
        }.stringify_keys }
    end

    def managers_and_enterprises
      query = Enterprise
        .joins("LEFT JOIN enterprise_roles ON enterprises.id = enterprise_roles.enterprise_id")
        .joins("LEFT JOIN spree_users AS managers ON enterprise_roles.user_id = managers.id")
        .where("enterprise_id IS NOT NULL")
        .where("user_id IS NOT NULL")

      if params[:enterprise_id_in].present?
        query = query.where("enterprise_id IN (?)",
                            params[:enterprise_id_in].split(',').map(&:to_i))
      end

      if params[:user_id_in].present?
        query = query.where("user_id IN (?)", params[:user_id_in].split(',').map(&:to_i))
      end

      query.order("enterprises.created_at DESC")
        .select(["enterprises.name",
                 "enterprises.sells",
                 "enterprises.visible",
                 "enterprises.is_primary_producer",
                 "enterprises.created_at",
                 "managers.email AS user_email"])
        .to_a
        .map { |x|
        {
          name: x.name,
          sells: x.sells,
          visible: (x.visible ? 't' : 'f'),
          is_primary_producer: (x.is_primary_producer ? 't' : 'f'),
          created_at: x.created_at.utc.iso8601,
          relationship_type: 'manages',
          user_email: x.user_email
        }.stringify_keys }
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
