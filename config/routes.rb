Rails.application.routes.draw do
  post '/email_processor' => 'griddler/emails#create', as: :email_processor
end
