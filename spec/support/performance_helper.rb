module OpenFoodNetwork
  module PerformanceHelper
    def multi_benchmark(num_samples)
      results = (0..num_samples).map do |i|
        ActiveRecord::Base.connection.query_cache.clear
        Rails.cache.clear

        result = Benchmark.measure { yield }

        puts result

        result.total
      end.drop(1) # Do not return the first sample

      puts (results.sum / results.count * 1000).round 0

      results
    end
  end
end
