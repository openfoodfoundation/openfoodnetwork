# frozen_string_literal: true

class BulkFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(field, **opts)
    # Mark field if it is changed (unsaved)
    changed_method = "#{field}_changed?"
    if object.respond_to?(changed_method) && object.public_send(changed_method)
      opts[:class] = "#{opts[:class]} changed".strip
    end

    super
  end
end
