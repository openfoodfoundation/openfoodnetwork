# frozen_string_literal: true

class ApplicationReflex < StimulusReflex::Reflex
  # Put application-wide Reflex behavior and callbacks in this file.
  #
  # Learn more at: https://docs.stimulusreflex.com/rtfm/reflex-classes
  #
  # If your ActionCable connection is: `identified_by :current_user`
  #   delegate :current_user, to: :connection
  #
  # If you need to localize your Reflexes, you can set the I18n locale here:
  #
  #   before_reflex do
  #     I18n.locale = :fr
  #   end
  #
  # For code examples, considerations and caveats, see:
  # https://docs.stimulusreflex.com/rtfm/patterns#internationalization
  include CanCan::ControllerAdditions

  delegate :current_user, to: :connection

  def current_ability
    Spree::Ability.new(current_user)
  end

  def with_locale(&block)
    I18n.with_locale(current_user.locale, &block)
  end
end
