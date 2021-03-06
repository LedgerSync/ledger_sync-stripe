# frozen_string_literal: true

# Define globally so it's only evaluated once.

STRIPE_RECORD_COLLECTION = LedgerSync::Test::RecordCollection.new(
  dir: File.join(LedgerSync::Stripe.root, 'spec/support/records')
)

module StripeHelpers # rubocop:disable Metrics/ModuleLength
  def authorized_headers(override = {})
    {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Authorization' => 'Bearer STRIPE_API_KEY',
      'Content-Type' => 'application/x-www-form-urlencoded',
      'User-Agent' => /.+/,
      'X-Stripe-Client-User-Agent' => /.+/
    }.merge(override)
  end

  def api_record_url(args = {})
    _record = args.fetch(:record)
    id      = args.fetch(:id, nil)
    params  = args.fetch(:params, {})

    resource_endpoint = stripe_client.class.ledger_resource_type_for(resource_class: resource.class).pluralize
    ret = "https://api.stripe.com/v1/#{resource_endpoint}"

    if id.present?
      ret += '/' unless ret.end_with?('/')
      ret += id.to_s
    end

    if params.present?
      uri = URI(ret)
      uri.query = params.to_query
      ret = uri.to_s
    end

    ret
  end

  def response_headers(overrides = {})
    {
      'Content-Type' => 'application/json'
    }.merge(overrides)
  end

  def stripe_client
    LedgerSync.ledgers.stripe.new_from_env
  end

  def stripe_env?
    @stripe_env ||= ENV.key?('USE_DOTENV_ADAPTOR_SECRETS')
  end

  def stripe_records
    @stripe_records ||= STRIPE_RECORD_COLLECTION
  end

  def stripe_resource_type
    record.to_s.gsub(/^stripe_/, '')
  end

  def stub_create_for_record
    send("stub_#{stripe_resource_type}_create")
  end

  def stub_create_request(body:, url:)
    stub_request(:post, url)
      .with(
        headers: authorized_headers
      )
      .to_return(
        status: 200,
        body: body.to_json
      )
  end

  def stub_delete_for_record
    send("stub_#{stripe_resource_type}_delete")
  end

  def stub_delete_request(args = {})
    body = args.fetch(:body)
    url  = args.fetch(:url)

    stub_request(:delete, url)
      .with(
        headers: authorized_headers
      )
      .to_return(
        status: 200,
        body: body.to_json,
        headers: {}
      )
  end

  def stub_find_for_record(params: {})
    send("stub_#{stripe_resource_type}_find", params)
  end

  def stub_find_request(response_body:, url:)
    stub_request(:get, url)
      .to_return(
        status: 200,
        body: (response_body.is_a?(Hash) ? response_body.to_json : response_body)
      )
  end

  def stub_search_for_record
    send("stub_#{stripe_resource_type}_search")
  end

  def stub_update_for_record(params: {})
    send("stub_#{stripe_resource_type}_update", params)
  end

  def stub_update_request(args = {})
    body = args.fetch(:body, '')
    url = args.fetch(:url)

    stub_request(:post, url)
      .with(
        headers: authorized_headers
      )
      .to_return(
        status: 200,
        body: body.to_json
      )
  end

  # Dynamically define helpers
  STRIPE_RECORD_COLLECTION.all.each do |record, opts|
    record = record.gsub('/', '_')
    url_method_name = "#{record}_url"

    define_method(url_method_name) do |**keywords|
      api_record_url(
        **{
          record: record
        }.merge(keywords)
      )
    end

    define_method("stub_#{record}_create") do
      stub_create_request(
        body: opts.hash,
        url: send(url_method_name)
      )
    end

    define_method("stub_#{record}_delete") do
      stub_delete_request(
        body: opts.hash,
        url: send(
          url_method_name,
          id: opts.id
        )
      )
    end

    define_method("stub_#{record}_find") do |params = {}|
      stub_find_request(
        response_body: opts.hash,
        url: send(
          url_method_name,
          params: params,
          id: opts.id
        )
      )
    end

    define_method("stub_#{record}_update") do |args = {}|
      params = args.fetch(:params, {})
      body = args.fetch(:body, opts.hash)
      stub_update_request(
        body: body,
        url: send(
          url_method_name,
          params: params,
          id: opts.id
        )
      )
    end
  end
end
