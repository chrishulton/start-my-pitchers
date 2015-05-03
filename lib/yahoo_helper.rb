class YahooHelper
  CLIENT_OPTIONS = {
    :access_token_path  => '/oauth/v2/get_token',
    :authorize_path     => '/oauth/v2/request_auth',
    :request_token_path => '/oauth/v2/get_request_token',
    :site               => 'https://api.login.yahoo.com'
  }

  def self.get_consumer
     @consumer ||= ::OAuth::Consumer.new(YAHOO_CREDENTIALS[:app_id], YAHOO_CREDENTIALS[:app_secret], CLIENT_OPTIONS)
  end

  def self.get_request_token(user)
    OAuth::RequestToken.new(self.get_consumer, user.yahoo_token, user.yahoo_secret)
  end

  def self.get_access_token(user)
    OAuth::AccessToken.new(self.get_consumer, user.yahoo_token, user.yahoo_secret)
  end

  def self.refresh_access_token!(user)
    request_token = get_request_token(user)
    new_access_token = request_token.get_access_token(oauth_session_handle: user.yahoo_session_handle)
    new_token_creds = new_access_token.params
    user.yahoo_token = new_token_creds[:oauth_token]
    user.yahoo_secret = new_token_creds[:oauth_token_secret]
    user.yahoo_session_handle = new_token_creds[:oauth_session_handle]
    user.save!
  end

  def self.get_user_leagues(user)
    begin
      access_token = self.get_access_token(user)
      url = "http://fantasysports.yahooapis.com/fantasy/v2/users;use_login=1/games;game_keys=mlb/leagues?format=json"
      resp = access_token.get(url)
      # unless resp.header.code == "200"
        # access_token = self.refresh_access_token(user)
        # resp = access_token.get(url)
      # end
      resp_body = MultiJson.load resp.body
      resp_body["fantasy_content"]["users"]["0"]["user"][1]["games"]["0"]["game"][1]["leagues"]["0"]["league"]
    rescue OAuth::Problem => error
      if error.message == "token_expired"
        self.refresh_access_token!(user)
        self.get_user_leagues(user)
      end
    end
  end

  # def self.get_client(access_token, application)
    # youtube_credentials = SOCIAL_NETWORK_CREDS[application]["google_oauth2"]
    # YouTubeIt::OAuth2Client.new(:client_id            => youtube_credentials["key"],
                                # :client_secret        => youtube_credentials["secret"],
                                # :client_access_token  => access_token['token'],
                                # :client_refresh_token => access_token['refresh_token'])
  # end
end
