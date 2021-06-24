# frozen_string_literal: true

module OpenFoodNetwork
  module PerformanceHelper
    def multi_benchmark(num_samples, cache_key_patterns: [], &block)
      results = (0..num_samples).map do |_i|
        ActiveRecord::Base.connection.query_cache.clear
        delete_cache_keys(cache_key_patterns)

        result = Benchmark.measure(&block)

        puts result

        result.total
      end.drop(1) # Do not return the first sample

      avg = (results.sum / results.count * 1000).round(0)
      puts avg

      results
    end

    # Looks for matching keys and deletes them
    # Blindly running `Rails.cache.clear` is harmful since it alters application
    # state outside executing spec example
    #
    # @param cache_key_patterns [Array<String>]
    def delete_cache_keys(cache_key_patterns)
      cache_key_patterns.each do |pattern|
        Rails.cache.delete_matched(pattern)
      end
    end
  end
end
