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
          cc: ccs,
          text: params['body-plain'],
          html: params['body-html'],
          headers: params['message-headers'],
          attachments: attachment_files
        )
      end

      private

      attr_reader :params

      def recipients
        params[:recipient].split(',')
      end

      def ccs
        cc = if params[:Cc].present?
          params[:Cc]
        else
          extract_header_cc
        end
        cc.split(',').map(&:strip)
      end

      def extract_header_cc
        header = params['message-headers'].select{|h|
          h.first == 'Cc'
        }.first
        header.to_a.last
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
