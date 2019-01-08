require "tasks/sample_data/addressing"
require "tasks/sample_data/logging"

class EnterpriseFactory
  include Logging
  include Addressing

  def create_samples(users)
    log "Creating enterprises:"
    enterprise_data(users).map do |data|
      name = data[:name]
      log "- #{name}"
      data[:long_description] = data[:long_description].strip_heredoc.tr("\n", " ")
      Enterprise.create_with(data).find_or_create_by_name!(name)
    end
  end

  private

  # rubocop:disable Metrics/MethodLength
  def enterprise_data(users)
    [
      {
        name: "Penny's Profile",
        owner: users["Penny Profile"],
        is_primary_producer: false,
        sells: "none",
        address: address("25 Myrtle Street, Bayswater, 3153")
      },
      {
        name: "Fred's Farm",
        owner: users["Fred Farmer"],
        is_primary_producer: true,
        sells: "none",
        address: address("6 Rollings Road, Upper Ferntree Gully, 3156")
      },
      {
        name: "Freddy's Farm Shop",
        owner: users["Freddy Shop Farmer"],
        is_primary_producer: true,
        sells: "own",
        address: address("72 Lake Road, Blackburn, 3130")
      },
      {
        name: "Fredo's Farm Hub",
        owner: users["Fredo Hub Farmer"],
        is_primary_producer: true,
        sells: "any",
        address: address("7 Verbena Street, Mordialloc, 3195")
      },
      {
        name: "Mary's Online Shop",
        owner: users["Mary Retailer"],
        is_primary_producer: false,
        sells: "any",
        address: address("20 Galvin Street, Altona, 3018")
      },
      {
        name: "Maryse's Private Shop",
        owner: users["Maryse Private"],
        is_primary_producer: false,
        sells: "any",
        address: address("6 Martin Street, Belgrave, 3160"),
        require_login: true
      }
    ]
  end
  # rubocop:enable Metrics/MethodLength
end
