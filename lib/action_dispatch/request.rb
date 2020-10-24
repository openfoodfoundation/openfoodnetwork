# This patch fixes the Rails issue where ActionDispatch::Request#deep_munge was converting empty
# array paramters into nils, see https://github.com/rails/rails/issues/13420
#
# Before this patch:
#
# | JSON                             | Hash                    |
# |----------------------------------|-------------------------|
# | { "person": [] }                 | { 'person' => nil }     |
#
# After patch:
#
# | JSON                             | Hash                    |
# |----------------------------------|-------------------------|
# | { "person": [] }                 | { 'person' => [] }      |
#
# The issue started in Rails v4.0.0.beta1:
#
# https://github.com/rails/rails/commit/8e577fe560d5756fcc67840ba304d79ada6804e4
#
# This patch can be removed on or after Rails v5.0.0.beta1 when the issue was fixed:
#
# https://github.com/rails/rails/commit/8f8ccb9901cab457c6e1d52bdb25acf658fd5777
#
# Credit:
#
# https://gist.github.com/victorblasco/f675b4cbaf9c0bc19f81

module ActionDispatch
  class Request
    def deep_munge(hash)
      hash.each do |k, v|
        case v
        when Array
          v.grep(Hash) { |x| deep_munge(x) }
          v.compact!

          # This patch removes the next line
          # hash[k] = nil if v.empty?
        when Hash
          deep_munge(v)
        end
      end

      hash
    end
  end
end
