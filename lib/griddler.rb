require 'rails/engine'
require 'action_view'
require 'griddler/errors'
require 'griddler/engine'
require 'griddler/email'
require 'griddler/email_parser'
require 'griddler/configuration'
require 'griddler/route_extensions'
require 'griddler/adapter_registry'
require 'griddler/adapters/sendgrid_adapter'
require 'griddler/adapters/cloudmailin_adapter'
require 'griddler/adapters/postmark_adapter'
require 'griddler/adapters/mandrill_adapter'
require 'griddler/adapters/mailgun_adapter'

module Griddler
  def self.adapter_registry
    @adapter_registry ||= AdapterRegistry.new
  end
end

Griddler.adapter_registry.register(:sendgrid, Griddler::Adapters::SendgridAdapter)
Griddler.adapter_registry.register(:cloudmailin, Griddler::Adapters::CloudmailinAdapter)
Griddler.adapter_registry.register(:postmark, Griddler::Adapters::PostmarkAdapter)
Griddler.adapter_registry.register(:mandrill, Griddler::Adapters::MandrillAdapter)
Griddler.adapter_registry.register(:mailgun, Griddler::Adapters::MailgunAdapter)
