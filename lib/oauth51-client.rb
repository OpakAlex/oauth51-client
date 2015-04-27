require "oauth51-client/version"
require "oauth51-client/base"
require "oauth51-client/client"
require "oauth51-client/user"
require "oauth51-client/configuration"

module Oauth51Client
  def self.configuration
    @configuration ||= Configuration.new
  end
  def self.configure
    yield(configuration)
  end

  def self.client_id
    return configuration.client_id unless configuration.client_id.nil?
    if defined?(Rails) && Rails.application.respond_to?(:secrets)
      return Rails.application.secrets.oauth['client_id']
    end

    raise "Cannot find client_id in rails config. Add it to your initializer"
  end

  def self.client_secret
    return configuration.client_secret unless configuration.client_secret.nil?
    if defined?(Rails) && Rails.application.respond_to?(:secrets)
      return Rails.application.secrets.oauth['client_secret']
    end

    raise "Cannot find client_secret in rails config. Add it to your initializer"
  end

  def self.server_url
    return configuration.server_url unless configuration.server_url.nil?
    if defined?(Rails) && Rails.application.respond_to?(:secrets)
      return Rails.application.secrets.oauth['app_url']
    end

    raise "Cannot find server_url in rails config. Add it to your initializer"
  end
end
