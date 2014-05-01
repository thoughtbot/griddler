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
          to: recipients(:to),
          cc: recipients(:cc),
          attachments: attachment_files,
          envelope: envelope,
          charsets: charsets,
          spf: params[:SPF]
        )
      end

      private

      attr_reader :params

      def recipients(key)
        ( params[key] || '' ).split(',')
      end

      def envelope
        JSON.parse(params[:envelope]).with_indifferent_access if params[:envelope].present?
      rescue JSON::ParserError
        nil
      end

      def charsets
        JSON.parse(params[:charsets]).with_indifferent_access if params[:charsets].present?
      rescue JSON::ParserError
        nil
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
