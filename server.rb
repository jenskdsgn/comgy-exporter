# frozen_string_literal: true

# Bundler setup
require 'rubygems'
require 'bundler/setup'

# Webserver serving metrics
require 'webrick'

require_relative './comgy_client'

PORT = 9111
ACCOUNT_TOKEN = ENV.fetch('COMGY_ACCOUNT_MASTER_KEY')

client = ComgyClient.new(ACCOUNT_TOKEN)

class ComgyServlet < WEBrick::HTTPServlet::AbstractServlet
  def initialize(server, client)
    super(server)
    @client = client
  end

  def do_GET(_request, response)
    metrics = @client.fetch_meter_readouts
    metrics_output = build_metrics_lines(metrics)

    response.status = 200
    response.content_type = 'text/plain'
    response.body = <<~BODY
      # HELP comgy_meter_value Latest meter value
      # TYPE comgy_meter_value gauge
      #{metrics_output}\n
    BODY
  end

  def build_metrics_lines(metrics)
    metrics.map do |metric|
      "comgy_meter_value{meter_identifier=\"#{metric[:meter_identifier]}\"} #{metric[:value]}"
    end.join("\n")
  end
end

server = WEBrick::HTTPServer.new(Port: PORT)

server.mount '/metrics', ComgyServlet, client

trap 'INT' do
  server.shutdown
end

server.start
