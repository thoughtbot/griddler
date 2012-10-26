Rails.application.routes.draw do
  match '/email_processor' => 'griddler/emails#create', via: :post, as: :email_processor
end
