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
        params[:to] = params[:ToFull][:Email]
        params[:from] = params[:FromFull][:Email]
        params[:subject] = params[:Subject]
        params[:text] = params[:TextBody]
        params[:html] = params[:HtmlBody]
        params[:attachments] = attachment_files
        params
      end

      private

      attr_reader :params

      def attachment_files
        attachments = Array(params[:Attachments])

        attachments.map do |attachment|
          filename = attachment[:Name]
          # third param is 1.9 only... is that ok?
          tempfile = Tempfile.new(filename, Dir::tmpdir, :encoding => 'ascii-8bit')
          tempfile.write(Base64.decode64(attachment[:Content]))
          tempfile.rewind
          ActionDispatch::Http::UploadedFile.new({
            filename: filename,
            type: attachment[:ContentType],
            tempfile: tempfile
          })
        end
      end

    end
  end
end
