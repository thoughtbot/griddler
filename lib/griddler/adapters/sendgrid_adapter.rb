module Griddler
  module Adapters
    class SendGridAdapter
      attr_accessor :params

      def initialize(params)
        @params = params
      end

      def self.normalize_params(params)
        adapter = new(params)
        adapter.normalize_params
      end

      def normalize_params
        params[:attachments] = attachment_files
        params
      end

      private

      def attachment_files
        params.delete('attachment-info')
        attachment_count = params[:attachments].to_i

        attachment_count.times.map do |index|
          params.delete("attachment#{index + 1}".to_sym)
        end
      end
    end
  end
end
