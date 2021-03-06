# frozen_string_literal: true

require 'oauth2'

module LedgerSync
  module Stripe
    class Client
      include Ledgers::Client::Mixin

      attr_reader :api_key

      def initialize(
        api_key:
      )
        @api_key = api_key

        super()
      end

      def url_for(resource:)
        DashboardURLHelper.new(
          resource: resource,
          base_url: 'https://dashboard.stripe.com'
        ).url
      end

      def wrap_perform
        ::Stripe.api_key = api_key
        yield
      ensure
        ::Stripe.api_key = nil
      end

      def self.ledger_attributes_to_save
        []
      end

      def self.new_from_env(**override)
        new(
          {
            api_key: ENV.fetch('STRIPE_API_KEY', nil)
          }.merge(override)
        )
      end
    end
  end
end
