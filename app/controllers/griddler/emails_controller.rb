class Griddler::EmailsController < ActionController::Base
  def create
    Griddler::Email.new(params)
    head :ok
  end
end
