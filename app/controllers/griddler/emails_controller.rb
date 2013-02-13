class Griddler::EmailsController < ActionController::Base
  def create
    params = config.adatper.adapt(params)
    Griddler::Email.new(params).process
    head :ok
  end
end
