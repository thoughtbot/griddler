class Griddler::EventsController < ActionController::Base
  def create
    Griddler::Event.process(request.raw_body)
    head :ok
  end
end
