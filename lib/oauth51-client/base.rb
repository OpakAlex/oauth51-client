require 'rest_client'

module Oauth51Client
  class Base
    def initialize(token, base_uri)
      @access_token = token
      @base_uri = base_uri
      @headers = {'Authorization' => "Bearer #{token}", accept: :json}
    end

    def me
      @me ||= self.call(:get, '/api/v1/users/me.json')
    end

    def call(method, endpoint, options = {})
      response = case method
                 when :post
                   RestClient.post "#{@base_uri}#{endpoint}", options, @headers
                 else
                   RestClient.get "#{@base_uri}#{endpoint}", @headers.merge(options)
                 end
      JSON.parse(response.body)
    end
  end
end
