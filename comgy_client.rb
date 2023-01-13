require 'uri'
require 'faraday'

class ComgyClient
  BASE_PATH = '/public/v0'
  HOST = 'api.comgy.io'

  def initialize(token)
    @token = token
  end

  # @example
  # [{:meter_identifier=>"19061274", :meter_mivd=>"DWZ-19061274-2-7", :value=>"0.096", :unit=>"m3"}]
  def fetch_meter_readouts
    meters = fetch_meters
  
    meters.filter_map do |meter|
      meter_value = fetch_meter_value(meter[:id])
  
      next if meter_value.nil?
  
      {
          meter_identifier: meter[:identifier],
          meter_mivd: meter[:mivd],
          value: meter_value[:value],
          unit: meter_value[:unit],
      }
    end
  end

  private

  # @example
  # [
  #   {:id=>"12313", :identifier=>"99191238", :mivd=>"DWZ-18061274-2-7"},
  #   {:id=>"12314", :identifier=>"77123919", :mivd=>"20124124"}
  # ]
  def fetch_meters
    url = build_resource_url('meters')

    response = Faraday.get(url, nil, headers)
    payload = JSON.parse(response.body, symbolize_names: true)

    payload[:data].map do |meter_resource|
      {
        id: meter_resource[:id],
        **meter_resource[:attributes].slice(:id, :identifier, :mivd),
      }
    end
  end

  # @example
  # {:value=>"0.096", :unit=>"m3"}
  def fetch_meter_value(meter_id)
    timestamp_yesterday = (Time.now - 86_400).strftime('%Y-%m-%dT%H:%M:%S.%L%z')
    url = build_resource_url("meters/#{meter_id}/meter-values")

    response = Faraday.get(url, { filter: { from: timestamp_yesterday } }, headers)
    payload = JSON.parse(response.body, symbolize_names: true)

    recent_value = payload[:data].max_by { |meter_value| meter_value[:attributes][:timestamp] }
  
    recent_value.nil? ? nil : recent_value.fetch(:attributes).slice(:value, :unit)
  end

  def build_resource_url(path)
    URI::HTTPS.build(
      host: HOST,
      path: [BASE_PATH, path].join('/')
    ).to_s
  end

  def headers
    @headers ||= {
      'Authorization' => "Bearer #{@token}"
    }
  end
end
