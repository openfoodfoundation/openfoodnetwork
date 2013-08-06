require 'spec_helper'

describe LandingPageImage do
  it { should have_attached_file(:photo) }
  it { should validate_attachment_presence(:photo) }
end
