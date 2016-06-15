class WelcomeController < ApplicationController

  before_action :authenticate_registered, only: :matchmaking

  def welcome
  end

  def matchmaking
  end

  def spectating
  end

  def administration
  end
end
