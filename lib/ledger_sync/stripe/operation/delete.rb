# frozen_string_literal: true

require_relative '../operation'

module LedgerSync
  module Stripe
    class Operation
      class Delete
        include Stripe::Operation::Mixin
      end
    end
  end
end
