module Griddler
  module Adapters
    class SendGridAdapter
      def self.normalize_params(params)
        attachment_count = params[:attachments].to_i

        attachment_files = attachment_count.times.map do |index|
          params.delete("attachment#{index + 1}".to_sym)
        end

        params.delete('attachment-info')
        params[:attachments] = attachment_files
        params
      end
    end
  end
end
