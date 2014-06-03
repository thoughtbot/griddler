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
require 'griddler/adapters/postmark_adapter'
require 'griddler/adapters/mailgun_adapter'

require 'griddler/sendgrid'
require 'griddler/mandrill'

Griddler.adapter_registry.register(:cloudmailin, Griddler::Adapters::CloudmailinAdapter)
Griddler.adapter_registry.register(:postmark, Griddler::Adapters::PostmarkAdapter)
Griddler.adapter_registry.register(:mailgun, Griddler::Adapters::MailgunAdapter)
