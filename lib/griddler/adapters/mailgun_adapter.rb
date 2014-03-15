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
          to: tos,
          cc: ccs,
          text: params['body-plain'],
          html: params['body-html'],
          headers: params['message-headers'],
          attachments: attachment_files
        )
      end

      private

      attr_reader :params

      def tos
        to = param_or_header(:To)
        to = params[:recipient] unless to
        to.split(',').map(&:strip)
      end

      def ccs
        cc = param_or_header(:Cc)
        cc.split(',').map(&:strip)
      end

      def extract_header(key)
        return nil unless params['message-headers'].present?

        headers = params['message-headers'].select do |h|
          h.first.to_s == key.to_s
        end
        headers.flatten.last
      end

      def param_or_header(key)
        if params[key].present?
          params[key]
        else
          extract_header(key)
        end
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
