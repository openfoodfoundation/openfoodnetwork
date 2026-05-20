# frozen_string_literal: true

# Parse response as JSON and provide common shortcuts.
#
# Rails parses JSON responses automatically and provides them in
# `response.parsed_body`. But when we reply with "application/ld+json" then
# Rails doesn't recognise it and doesn't parse it.
RSpec.shared_context "JSON LD" do
  # An endpoint can respond with a single object, also called the "subject".
  # That aligns perfectly with the RSpec subject naming.
  subject {
    JSON.parse(response.body, object_class: ActiveSupport::HashWithIndifferentAccess)
  }

  # When the response contains multiple objects, they are listed in a graph.
  # The subject is often the first in the graph but not all platforms conform
  # to that. Some list objects alphabetically by id.
  let(:graph) {
    subject["@graph"]
  }
end
