# frozen_string_literal: true

class FakeBlob
  def filename
    "test-report.csv"
  end

  def expiring_service_url
    "http://example.com/test-report.csv"
  end
end
