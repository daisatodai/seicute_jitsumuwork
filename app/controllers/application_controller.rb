# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def not_authenticated
    redirect_to new_session_path, danger: "ログインしてください"
  end

end
