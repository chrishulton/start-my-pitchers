class HomesController < ApplicationController
  def index
    unless current_user
      redirect_to new_user_session_path
    end

    @league = ::YahooHelper.get_user_league(current_user)
    @team = ::YahooHelper.get_user_team(current_user)

    team_key = @team["team_key"]

    players = ::YahooHelper.get_user_team_roster(current_user, team_key)
    @pitchers = players.select{ |p| p["display_position"] =~ /(SP)|(RP)/ }
  end
end
