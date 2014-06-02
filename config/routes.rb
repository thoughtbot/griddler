Rails.application.routes.draw do
  controller = Griddler.configuration.controller_route
  post '/email_processor' => "#{controller}#create", as: :email_processor
end
