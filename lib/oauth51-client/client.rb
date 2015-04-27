module Oauth51Client
  class Client < Base
    def social_authentication_for?(social_network)
      self.me['authentications'].key? social_network.to_s
    end
    def get_twitter_uid
      self.me.fetch('authentications', {}).fetch('twitter', {}).fetch('uid', '')
    end

    def get_instagram_uid
      self.me.fetch('authentications', {}).fetch('instagram', {}).fetch('uid', '')
    end

    def get_facebook_token
      self.me.fetch('authentications', {}).fetch('facebook', {}).fetch('authentication_token', '')
    end

    def activity
      call :get, '/api/v1/users/activity.json'
    end

    def add_points(points, action = 'add_points')
      call :post, '/api/v1/users/add_points.json', {point: {points: points, action: action}}
    end

    def remove_points(points, action = 'remove_points')
      call :post, '/api/v1/users/remove_points.json', {point: {points: points, action: action}}
    end

    def total_points
      json = self.activity
      points = json["points"] if json

      return points || 0
    end

    def profile_completeness
      json = self.me

      return json["profile_completeness"] if json
    end
  end
end
