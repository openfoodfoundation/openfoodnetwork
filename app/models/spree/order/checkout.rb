# frozen_string_literal: true

module Spree
  class Order < ApplicationRecord
    module Checkout
      def self.included(klass)
        klass.class_eval do
          class_attribute :next_event_transitions
          class_attribute :previous_states
          class_attribute :checkout_flow
          class_attribute :checkout_steps

          def self.checkout_flow(&block)
            if block_given?
              @checkout_flow = block
              define_state_machine!
            else
              @checkout_flow
            end
          end

          def self.define_state_machine!
            self.checkout_steps = {}
            self.next_event_transitions = []
            self.previous_states = [:cart]

            # Build the checkout flow using the checkout_flow defined either
            # within the Order class, or a decorator for that class.
            #
            # This method may be called multiple times depending on if the
            # checkout_flow is re-defined in a decorator or not.
            instance_eval(&checkout_flow)

            klass = self

            # To avoid a ton of warnings when the state machine is re-defined
            StateMachines::Machine.ignore_method_conflicts = true
            # To avoid multiple occurrences of the same transition being defined
            # On first definition, state_machines will not be defined
            state_machines.clear if respond_to?(:state_machines)
            state_machine :state, initial: :cart do
              klass.next_event_transitions.each { |t| transition(t.merge(on: :next)) }

              # Persist the state on the order
              after_transition do |order|
                order.state = order.state
                order.save
              end

              event :cancel do
                transition to: :canceled, if: :allow_cancel?
              end

              event :return do
                transition to: :returned, from: :awaiting_return, unless: :awaiting_returns?
              end

              event :resume do
                transition to: :resumed, from: :canceled, if: :allow_resume?
              end

              event :authorize_return do
                transition to: :awaiting_return
              end

              event :restart_checkout do
                transition to: :cart, unless: :completed?
              end

              event :confirm do
                transition to: :complete, from: :confirmation
              end

              before_transition from: :cart, do: :ensure_line_items_present

              before_transition to: :delivery, do: :create_proposed_shipments
              before_transition to: :delivery, do: :ensure_available_shipping_rates
              before_transition to: :confirmation, do: :validate_payment_method!

              after_transition to: :payment do |order|
                order.create_tax_charge!
                order.update_totals_and_states
              end

              after_transition to: :confirmation do |order|
                VoucherAdjustmentsService.new(order).update
                order.update_totals_and_states
              end

              after_transition to: :complete, do: :finalize!
              after_transition to: :resumed,  do: :after_resume
              after_transition to: :canceled, do: :after_cancel
            end
          end

          def self.go_to_state(name, options = {})
            checkout_steps[name] = options
            previous_states.each do |state|
              add_transition({ from: state, to: name }.merge(options))
            end
            if options[:if]
              previous_states << name
            else
              self.previous_states = [name]
            end
          end

          def self.next_event_transitions
            @next_event_transitions ||= []
          end

          def self.checkout_steps
            @checkout_steps ||= {}
          end

          def self.add_transition(options)
            next_event_transitions << { options.delete(:from) => options.delete(:to) }.
              merge(options)
          end

          def checkout_steps
            steps = self.class.checkout_steps.
              each_with_object([]) { |(step, options), checkout_steps|
              next if options.include?(:if) && !options[:if].call(self)

              checkout_steps << step
            }.map(&:to_s)
            # Ensure there is always a complete step
            steps << "complete" unless steps.include?("complete")
            steps
          end

          def restart_checkout_flow
            update_columns(
              state: checkout_steps.first,
              updated_at: Time.zone.now,
            )
          end

          def state_changed(name)
            state = "#{name}_state"
            return unless persisted?

            old_state = __send__("#{state}_was")
            state_changes.create(
              previous_state: old_state,
              next_state: __send__(state),
              name: name,
              user_id: user_id
            )
          end

          private

          def after_cancel
            shipments.reject(&:canceled?).each(&:cancel!)
            payments.checkout.each(&:void!)

            OrderMailer.cancel_email(id).deliver_later if send_cancellation_email
            update(payment_state: updater.update_payment_state)
          end

          def after_resume
            shipments.each(&:resume!)
            payments.void.each(&:resume!)

            update(payment_state: updater.update_payment_state)
          end

          def validate_payment_method!
            return unless checkout_processing
            return if payments.any?

            errors.add :payment_method, I18n.t('split_checkout.errors.select_a_payment_method')
            throw :halt
          end
        end
      end
    end
  end
end
