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
          to: extract_recipients(:ToFull),
          cc: extract_recipients(:CcFull),
          from: full_email(params[:FromFull]),
          subject: params[:Subject],
          text: params[:TextBody],
          html: params[:HtmlBody],
          attachments: attachment_files,
        }
      end

      private

      attr_reader :params

      def extract_recipients(key)
        params[key].to_a.map { |recipient| full_email(recipient) }
      end

      def full_email(contact_info)
        email = contact_info[:Email]
        if contact_info[:Name].present?
          "#{contact_info[:Name]} <#{email}>"
        else
          email
        end
      end

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
