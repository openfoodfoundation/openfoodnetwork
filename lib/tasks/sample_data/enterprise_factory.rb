# frozen_string_literal: true

require "tasks/sample_data/addressing"
require "tasks/sample_data/logging"

module SampleData
  class EnterpriseFactory
    include Logging
    include Addressing

    def create_samples(users)
      log "Creating enterprises:"
      enterprise_data(users).map do |data|
        name = data[:name]
        log "- #{name}"
        data[:long_description] = data[:long_description].strip_heredoc.tr("\n", " ")
        Enterprise.create_with(data).find_or_create_by!(name: name)
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
          address: address("25 Myrtle Street, Bayswater, 3153"),
          long_description: <<DESC
          This enterprise is a profile which means that it's not a producer and it
          doesn't sell anything either.
DESC
        },
        {
          name: "Fred's Farm",
          owner: users["Fred Farmer"],
          is_primary_producer: true,
          sells: "none",
          address: address("6 Rollings Road, Upper Ferntree Gully, 3156"),
          long_description: <<DESC
          This enterprise is a producer only. It has products, which are sold
          through the online shops of other enterprises.
DESC
        },
        {
          name: "Freddy's Farm Shop",
          owner: users["Freddy Shop Farmer"],
          is_primary_producer: true,
          sells: "own",
          address: address("72 Lake Road, Blackburn, 3130"),
          long_description: <<DESC
          This enterprise is a producer which also sells directly to consumers.
          It has its own online shop and sells through other enterprises.
DESC
        },
        {
          name: "Fredo's Farm Hub",
          owner: users["Fredo Hub Farmer"],
          is_primary_producer: true,
          sells: "any",
          address: address("7 Verbena Street, Mordialloc, 3195"),
          long_description: <<DESC
          This enterprise is a producer selling its own and other produce to
          consumers.
DESC
        },
        {
          name: "Mary's Online Shop",
          owner: users["Mary Retailer"],
          is_primary_producer: false,
          sells: "any",
          address: address("20 Galvin Street, Altona, 3018"),
          long_description: <<DESC
          This enterprise sells the products of producers, but doesn't have any
          products of its own.
DESC
        },
        {
          name: "Maryse's Private Shop",
          owner: users["Maryse Private"],
          is_primary_producer: false,
          sells: "any",
          address: address("6 Martin Street, Belgrave, 3160"),
          require_login: true,
          long_description: <<DESC
          This enterprise sells the products of producers in a private shop front.
          Users have to be registered customers of this enterprise to access the
          shop.
DESC
        }
      ]
    end
    # rubocop:enable Metrics/MethodLength
  end
end
