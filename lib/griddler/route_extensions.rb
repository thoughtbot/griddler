module Griddler
  module RouteExtensions
    def mount_griddler(path='/email_processor')
      post path => 'griddler/emails#create', as: :email_processor
    end
  end
end
