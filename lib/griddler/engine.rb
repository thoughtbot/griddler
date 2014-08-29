module Griddler
  class Engine < ::Rails::Engine
    initializer 'griddler.routes',
      after: 'action_dispatch.prepare_dispatcher' do |app|

      ActionDispatch::Routing::Mapper.send :include, Griddler::RouteExtensions
    end
  end if defined?(::Rails::Engine)
end
