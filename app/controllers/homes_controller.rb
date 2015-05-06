class HomesController < ApplicationController
  def index
    unless current_user
      return redirect_to new_user_session_path
    end

    @league = ::YahooHelper.get_user_league(current_user)
    @team = ::YahooHelper.get_user_team(current_user)

    team_key = @team["team_key"]

    @week_pitchers = {}

    (Date.today.beginning_of_week..Date.today.end_of_week).each do |date|
      players = ::YahooHelper.get_user_team_roster(current_user, team_key, date)
      pitchers = players.select{ |p| p["display_position"] =~ /(SP)|(RP)/ }
      @week_pitchers[date] = pitchers
    end
  end
end
