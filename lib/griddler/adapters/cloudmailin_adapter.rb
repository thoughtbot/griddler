module Griddler
  module Adapters
    class CloudmailinAdapter
      def initialize(params)
        @params = params
        @normalized_params = {}
      end

      def self.normalize_params(params)
        adapter = new(params)
        adapter.normalize_params
      end

      def normalize_params
        normalized_params[:to] = params[:envelope][:to]
        normalized_params[:from] = params[:envelope][:from]
        normalized_params[:subject] = params[:headers][:Subject]
        normalized_params[:text] = params[:plain]
        normalized_params[:attachments] = params[:attachments] || []
        normalized_params
      end

      private

      attr_reader :params, :normalized_params

    end
  end
end
