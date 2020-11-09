# frozen_string_literal: true

require 'dotenv'

require 'ledger_sync/test/support'
require 'climate_control'

LedgerSync::Test::Support.setup('ledger_sync/stripe')

setup_client_qa_support(LedgerSync::Stripe::Client)
