module Griddler
  module Adapters
    class PostmarkAdapter
      def initialize(params)
        @params = params
      end

      def self.normalize_params(params)
        adapter = new(params)
        adapter.normalize_params
      end

      def normalize_params
        {
          to: params[:ToFull].first[:Email],
          from: params[:FromFull][:Email],
          subject: params[:Subject],
          text: params[:TextBody],
          html: params[:HtmlBody],
          attachments: attachment_files,
        }
      end

      private

      attr_reader :params

      def attachment_files
        attachments = Array(params[:Attachments])

        attachments.map do |attachment|
          ActionDispatch::Http::UploadedFile.new({
            filename: attachment[:Name],
            type: attachment[:ContentType],
            tempfile: create_tempfile(attachment)
          })
        end
      end

      def create_tempfile(attachment)
        filename = attachment[:Name]
        tempfile = Tempfile.new(filename, Dir::tmpdir, encoding: 'ascii-8bit')
        tempfile.write(Base64.decode64(attachment[:Content]))
        tempfile.rewind
        tempfile
      end
    end
  end
end
