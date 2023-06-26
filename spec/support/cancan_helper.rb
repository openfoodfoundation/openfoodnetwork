# frozen_string_literal: true

# From: https://github.com/ryanb/cancan/wiki/Testing-Abilities#rspec

require "cancan/matchers"

module Spree
  RSpec::Matchers.define :have_ability do |ability_hash, options = {}|
    match do |user|
      ability         = Ability.new(user)
      target          = options[:for]
      @ability_result = {}
      # e.g.: :create => {:create => true}
      ability_hash    = { ability_hash => true } if ability_hash.is_a? Symbol
      if ability_hash.is_a? Array
        ability_hash = ability_hash.inject({}){ |member, i|
          member.merge(i => true)
        }
      end
      ability_hash.each do |action, _true_or_false|
        @ability_result[action] = ability.can?(action, target)
      end

      expect(ability_hash).to eq(@ability_result)
    end

    failure_message do |user|
      ability_hash, options = expected
      ability_hash = { ability_hash => true } if ability_hash.is_a? Symbol # e.g.: :create
      if ability_hash.is_a? Array
        ability_hash = ability_hash.inject({}){ |member, i|
          member.merge(i => true)
        }
      end
      target = options[:for]
      message = "expected User:#{user} to have ability: #{ability_hash} for #{target}, " \
                "but actual result is #{@ability_result}"
    end

    # to clean up output of RSpec Documentation format
    description do
      target = expected.last[:for]
      "have ability #{ability_hash.keys.join(', ')} for #{target.class.name}"
    end
  end
end
