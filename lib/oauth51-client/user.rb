module Oauth51Client
  module User
    # Check that all requirements in secrets and User are satisfied
    def self.included(klass)
      klass.extend(ClassMethods)
      if Oauth51Client.client_id.nil? || Oauth51Client.client_secret.nil? || Oauth51Client.server_url.nil?
        raise 'Secrets not configured properly, please provide oauth: {client_id: --, client_secret: --, app_url: --} or define such data in an initializer'
      end
      if defined? Rails
        if klass.table_exists?
          new_instance = klass.new
          missing_methods = []
          [:o51_authentication_token, :o51_authentication_token_secret].each do |m|
            begin
              new_instance.send m
            rescue NoMethodError
              missing_methods << m
            end
          end
          if missing_methods.any?
            Rails.logger.error "#{klass} instances shall provide #{missing_methods.join(', ')} methods. This is fine if you're just running migrations but Oauth51Client::User relyes on those methods"
          end
        end
      end
    end

    def has_valid_credentials?
      o51_authentication_token.present? || !o51_token_expired?
    end

    # Refresh and updates user profile
    def o51_profile!
      update_attribute :o51_profile, o51_client.me
      o51_profile
    end

    # Returns if the user is a moderator
    def is_moderator?
      o51_profile.fetch('moderator', false)
    end

    # Retruns a Oauth51::Client instance for the included model, relying on o51_authentication_token!
    def o51_client
      unless o51_authentication_token.blank?
        @o51_client ||= Oauth51Client::Client.new(o51_authentication_token!, Oauth51Client.server_url)
      end
    end

    # Check if authentication token is expired
    def o51_token_expired?
      o51_expires_at.nil? || (o51_expires_at < Time.now)
    end

    # Refresh the token if needed
    def o51_authentication_token!
      o51_refesh_token
      o51_authentication_token
    end

    # Refresh the token
    def o51_refesh_token
      if o51_token_expired? && o51_authentication_token_secret.present?
        response = RestClient.post "#{Oauth51Client.server_url}/oauth/token",
          grant_type: 'refresh_token',
          refresh_token: o51_authentication_token_secret,
          client_id: Oauth51Client.client_id,
          client_secret: Oauth51Client.client_secret

        oauth_response = JSON.parse(response.body)

        self.o51_authentication_token = oauth_response['access_token']
        self.o51_authentication_token_secret = oauth_response['refresh_token']
        self.o51_expires_at = oauth_response["expires_in"].to_i.seconds.since
        self.save
      end
    end

    module ClassMethods
      def o51_from_omniauth(auth)
        this_user = where(o51_uid: auth.uid).first_or_initialize do |user|
          random_psw = Devise.friendly_token[0,20]
          user.password = random_psw
        end

        this_user.o51_authentication_token = auth.credentials.token
        this_user.o51_authentication_token_secret = auth.credentials.refresh_token
        this_user.o51_expires_at = (Time.at(auth.credentials.expires_at) rescue nil)
        this_user.o51_profile = this_user.o51_client.me
        this_user.o51_avatar_url = this_user.o51_profile['avatar_url']
        this_user.email = auth.info.email

        this_user.city = this_user.o51_profile['city'] if this_user.respond_to?('city=')
        this_user.province = this_user.o51_profile['province'] if this_user.respond_to?('province=')
        this_user.fullname = this_user.o51_profile['name'] if this_user.respond_to?('fullname=')
        this_user.o51_points = this_user.o51_profile['points'] if this_user.respond_to?('o51_points=')

        this_user.save
        this_user
      end
    end
  end
end
