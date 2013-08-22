class Griddler::EmailsController < ActionController::Base
  before_filter :authorize, if: ->{ Griddler.configuration.auth_token }

  def create
    normalized_params.each do |p|
      Griddler::Email.new(p).process
    end
    head :ok
  end

  private

  def normalized_params
    Array.wrap(Griddler.configuration.email_service.normalize_params(params))
  end

  def authorize
    unless Griddler.configuration.auth_token == params[:token]
      render text: 'Please use a token', status: :unauthorized
      return false
    end
  end
end
