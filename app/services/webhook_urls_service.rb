# frozen_string_literal: true

# Collect the webhook urls configured for a given webhook type by the people who
# manage an order cycle coordinator: its owner and its managers.

class WebhookUrlsService
  def self.for_coordinator(coordinator, webhook_type:)
    # url for coordinator owner
    webhook_urls = endpoint_urls(coordinator.owner, webhook_type)

    # plus url for coordinator manager (ignore duplicate)
    users_webhook_urls = coordinator.users.flat_map do |user|
      endpoint_urls(user, webhook_type)
    end

    webhook_urls | users_webhook_urls
  end

  def self.endpoint_urls(user, webhook_type)
    user.webhook_endpoints.where(webhook_type:).pluck(:url)
  end

  private_class_method :endpoint_urls
end
