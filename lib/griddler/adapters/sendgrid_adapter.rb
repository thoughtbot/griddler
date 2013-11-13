module Griddler
  module Adapters
    class SendgridAdapter
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
          cc: bcc,
          smtp: smtp,
          in_reply_to: in_reply_to,
          attachments: attachment_files,
        )
      end

      private

      attr_reader :params

      def smtp
        return @smtp unless @smtp.nil?
        @smtp = $1 if params['headers'] =~ /Message-ID:\s+\<([^\>\s]+)\>/im
      end

      def in_reply_to
        return @in_reply_to unless @in_reply_to.nil?
        @in_reply_to = $1 if params['headers'] =~ /In-Reply-To:\s+\<([^\>\s]+)\>?/im
      end

      def recipients
        params[:to].split(',')
      end

      def cc
        params[:cc].to_s.split(',')
      end

      def bcc
        params[:bcc].to_s.split(',')
      end

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
