# frozen_string_literal: true

module LedgerSync
  module Stripe
    class Customer
      module Operations
        class Delete < Stripe::Operation::Delete
          class Contract < LedgerSync::Ledgers::Contract
            params do
              required(:external_id).maybe(:string)
              required(:ledger_id).filled(:string)
              required(:email).maybe(:string)
              required(:name).maybe(:string)
              required(:phone_number).maybe(:string)
            end
          end

          private

          def operate
            stripe_customer = ::Stripe::Customer.delete(resource.ledger_id)

            success(
              resource: resource,
              response: stripe_customer
            )
          end
        end
      end
    end
  end
end
