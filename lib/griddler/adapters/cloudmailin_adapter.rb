module Griddler
  module Adapters
    class CloudmailinAdapter
      def initialize(params)
        @params = params
      end

      def self.normalize_params(params)
        adapter = new(params)
        adapter.normalize_params
      end

      def normalize_params
        params[:to] = params[:envelope][:to]
        params[:from] = params[:envelope][:from]
        params[:subject] = params[:headers][:Subject]
        params[:text] = params[:plain]
        params
      end

      private

      attr_reader :params

    end
  end
end
