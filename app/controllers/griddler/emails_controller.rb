class Griddler::EmailsController < ActionController::Base
  def create
    Griddler::Email.new(params).process
    head :ok
  end
end
