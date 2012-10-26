class Griddler::EmailsController < ApplicationController
  def create
    Griddler::Email.new(params)
    head :ok
  end
end
