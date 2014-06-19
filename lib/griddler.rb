require 'rails/engine'
require 'action_view'
require 'griddler/errors'
require 'griddler/engine'
require 'griddler/email'
require 'griddler/email_parser'
require 'griddler/configuration'
require 'griddler/route_extensions'
require 'griddler/adapter_registry'
require 'griddler/adapters/cloudmailin_adapter'

require 'griddler/sendgrid'
require 'griddler/mandrill'
require 'griddler/mailgun'
require 'griddler/postmark'

Griddler.adapter_registry.register(:cloudmailin, Griddler::Adapters::CloudmailinAdapter)
