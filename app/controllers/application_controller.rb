class ApplicationController < ActionController::Base
  attr_accessor :current_user

  # disable the CSRF token
  protect_from_forgery with: :null_session

  # disable cookies (no set-cookies header in response)
  before_action :destroy_session

  # disable the CSRF token
  skip_before_action :verify_authenticity_token

  # before_action :doorkeeper_authorize!
  before_action :authentication_user

  def destroy_session
    request.session_options[:skip] = true
  end


  private

  def authentication_user
    response = Response.rescue do |res|
      user = current_user
      res.raise_error('Authenticate failed') unless user.present?
    end
    render json: {status: response}.to_json unless response.code == Response::Code::SUCCESS
  end


  def get_current_user
    user = nil
    user_session_key = params[:user_session_key]
    user_string = $redis.get("user_#{user_session_key}")
    if user_string.present?
      user = User.new.from_json(JSON.parse(user_string).to_json)
    end
    user
  end

  def current_user
    return @current_user if @current_user.present?
    @current_user = get_current_user
    params[:user] = @current_user
    p "@current_user = #{@current_user}"
    @current_user
  end

end
