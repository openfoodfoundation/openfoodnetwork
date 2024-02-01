# frozen_string_literal: true

module DatabaseHelper
  extend RSpec::Matchers::DSL

  matcher :query_database do |expected = nil| # rubocop:disable Metrics/BlockLength
    match do |block|
      @queries = scribe_queries(&block)

      if expected.nil?
        !@queries.empty?
      elsif expected.is_a?(Integer)
        @queries.size == expected
      elsif expected.is_a?(Array)
        query_names == expected
      else
        raise "What are you expecting?"
      end
    end

    failure_message do |_block|
      <<~MESSAGE
        Expected database queries: #{expected}
        Actual database queries:   #{query_names}

        Diff: #{RSpec::Expectations.differ.diff_as_object(query_names, expected)}

        Full query log:

        #{query_descriptions.join("\n")}
      MESSAGE
    end

    failure_message_when_negated do |_block|
      "Expected no database queries but observed:\n\n#{query_descriptions.join("\n")}"
    end

    def supports_block_expectations?
      true
    end

    def query_names
      @queries.map { |q| q[:name] || q[:sql].split.take(2).join(" ") }
    end

    def query_descriptions
      @queries.map { |q| "#{q[:name]}  #{q[:sql]}" }
    end

    def scribe_queries(&)
      queries = []

      logger = ->(_name, _started, _finished, _unique_id, payload) {
        queries << payload unless payload[:name].in? %w[CACHE SCHEMA]
      }

      ActiveSupport::Notifications.subscribed(logger, "sql.active_record", &)

      queries
    end
  end

  def expect_query_count(&)
    expect(count_db_queries(&))
  end

  def count_db_queries(&)
    count = 0

    counter_f = ->(_name, _started, _finished, _unique_id, payload) {
      count += 1 unless payload[:name].in? %w[CACHE SCHEMA]
    }

    ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &)

    count
  end
end
