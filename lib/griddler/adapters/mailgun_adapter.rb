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
          text: params['body-plain'].to_s,
          html: params['body-html'].to_s,
          headers: headers,
          attachments: attachment_files,
          stripped_text: params['stripped-text'],
          stripped_html: params['stripped-html'],
          stripped_signature: params['stripped-signature']
        )
      end

      private

      attr_reader :params

      def smtp
        params['Message-Id'] || params['Message-ID']
      end

      def in_reply_to
        params['In-Reply-To']
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

      def headers
        return "" if params['message-headers'].nil? || params['message-headers'] == ""
        JSON(params['message-headers'])
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
