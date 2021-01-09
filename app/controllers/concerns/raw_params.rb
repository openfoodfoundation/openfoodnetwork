# frozen_string_literal: true

# In Rails 5, the params object no longer responds in the same way. It is not a hash but an object,
# it does not have indifferent access, and non-permitted attributes are removed. In order to access
# the raw params directly, we need to call params.to_unsafe_h

module RawParams
  extend ActiveSupport::Concern

  private

  def raw_params
    @raw_params ||= params.to_unsafe_h
  end
end
