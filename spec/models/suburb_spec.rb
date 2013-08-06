require 'spec_helper'

describe Suburb do
  it { should belong_to(:state) }
end
