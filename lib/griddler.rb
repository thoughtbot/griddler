if defined?(::Rails::Engine)
  require 'rails/engine'
  require 'griddler/engine'
end
require 'action_view'
require 'griddler/errors'
require 'griddler/email'
require 'griddler/email_parser'
require 'griddler/configuration'
require 'griddler/route_extensions'
require 'griddler/adapter_registry'
