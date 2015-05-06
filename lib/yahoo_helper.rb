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

  def self.get_user_league(user)
    url = "http://fantasysports.yahooapis.com/fantasy/v2/users;use_login=1/games;is_available=1;game_keys=mlb/leagues?format=json"
    resp_body = self.make_user_api_request(user, url)
    resp_body["fantasy_content"]["users"]["0"]["user"][1]["games"]["0"]["game"][1]["leagues"]["0"]["league"][0]
  end

  def self.get_user_team(user)
    url = "http://fantasysports.yahooapis.com/fantasy/v2/users;use_login=1/games;is_available=1;game_keys=mlb/teams?format=json"
    resp_body = self.make_user_api_request(user, url)
    team_data = resp_body["fantasy_content"]["users"]["0"]["user"][1]["games"]["0"]["game"][1]["teams"]["0"]["team"][0]
    team_data.select{ |k| k.class == Hash }.reduce Hash.new, :merge
  end

  def self.get_user_team_roster(user, team_key, date)
    url = "http://fantasysports.yahooapis.com/fantasy/v2/team/#{team_key}/roster;date=#{date}/players?format=json"
    resp_body = self.make_user_api_request(user, url)
    #XXX WHAT IS THIS FORMAT ????
    roster_resp = resp_body["fantasy_content"]["team"][1]["roster"]["0"]["players"]
    players = []

    roster_resp.values.each do |player|
      if player.class == Hash
        player_data = {}
        player_resp = player["player"]
        player_meta = player_resp[0].select{ |k| k.class == Hash }.reduce Hash.new, :merge
        player_data.merge!(player_meta)

        (1..2).each do |num|
          if player_resp[num].class == Hash
            player_resp[num].each do |k,v|
              player_resp[num][k] = v.reduce Hash.new, :merge
            end
            player_data.merge!(player_resp[num])
          end
        end
        player_data.merge!(player_resp[3])
        players << player_data
      end
    end
    players
  end

  private

  def self.make_user_api_request(user, url)
    begin
      access_token = self.get_access_token(user)
      resp = access_token.get(url)
      resp_body = MultiJson.load resp.body
      resp_body
    rescue OAuth::Problem => error
      if error.message == "token_expired"
        self.refresh_access_token!(user)
        self.make_user_api_request(user, url)
      end
    end
  end
end
