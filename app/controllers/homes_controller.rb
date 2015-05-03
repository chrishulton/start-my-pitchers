class HomesController < ApplicationController
  def index
    unless current_user
      redirect_to new_user_session_path
    end

    @leagues = []
    if current_user
      @leagues = ::YahooHelper.get_user_leagues(current_user)
    end
  end
end
