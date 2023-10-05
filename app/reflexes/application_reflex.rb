# frozen_string_literal: true

class ApplicationReflex < StimulusReflex::Reflex
  # Put application-wide Reflex behavior and callbacks in this file.
  #
  # Learn more at: https://docs.stimulusreflex.com/rtfm/reflex-classes
  #
  # For code examples, considerations and caveats, see:
  # https://docs.stimulusreflex.com/rtfm/patterns#internationalization
  include CanCan::ControllerAdditions

  delegate :current_user, to: :connection

  before_reflex do
    I18n.locale = current_user.locale
  end

  private

  def current_ability
    Spree::Ability.new(current_user)
  end

  def with_locale(&)
    I18n.with_locale(current_user.locale, &)
  end

  def morph_admin_flashes
    morph "#flashes", render(partial: "admin/shared/flashes", locals: { flashes: flash })
  end
end
