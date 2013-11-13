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
          cc: cc,
          bcc: bcc,
          smtp: smtp,
          in_reply_to: in_reply_to,
          text: params['body-plain'],
          html: params['body-html'],
          headers: JSON(params['message-headers']),
          attachments: attachment_files
        )
      end

      private

      attr_reader :params

      def smtp
        scrub_smtp(params['Message-Id'] || params['Message-ID'])
      end

      def in_reply_to
        scrub_smtp(params['In-Reply-To'])
      end

      def scrub_smtp(message_id)
        message_id.to_s.gsub(/\</, '').gsub(/\>/, '').strip
      end

      def recipients
        (params['To'] || params[:recipient]).to_s.split(',')
      end

      def cc
        params['Cc'].to_s.split(',')
      end

      def bcc
        params['Bcc'].to_s.split(',')
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
