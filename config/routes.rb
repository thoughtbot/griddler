Rails.application.routes.draw do
  controller = Griddler.configuration.controller_class.name.underscore.sub('_controller', '')
  post '/email_processor' => "#{controller}#create", as: :email_processor
end
