module Griddler
  module Adapters
    class MailgunAdapter
      def initialize(params)
        @params = params
      end

      def self.normalize_params(params)
        adapter = new(params)
        adapter.normalize_params
      end

      def normalize_params
        params.merge(
          to: recipients,
          text: params['body-plain'],
          html: params['body-html'],
          headers: params['message-headers'],
          attachments: attachment_files
        )
      end

      private

      attr_reader :params

      def recipients
        params[:recipient].to_s.split(',')
      end

      def attachment_files
        attachment_count = params['attachment-count'].to_i

        attachment_count.times.map do |index|
          params.delete("attachment-#{index+1}")
        end
      end
    end
  end
end
