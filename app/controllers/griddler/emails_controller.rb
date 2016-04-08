class Griddler::EmailsController < ActionController::Base
  include Griddler::Controller

  def create
    process_griddler
    head :ok
  end
end
