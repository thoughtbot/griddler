module Griddler
  module Adapters
    class MandrillAdapter
      def initialize(params)
        @params = params
      end

      def self.normalize_params(params)
        adapter = new(params)
        adapter.normalize_params
      end

      def normalize_params
        events.map do |event|
          {
            to: recipients(:to, event),
            cc: recipients(:cc, event),
            from: full_email([ event[:from_email], event[:from_name] ]),
            subject: event[:subject],
            text: event.fetch(:text, ''),
            html: event.fetch(:html, ''),
            raw_body: event[:raw_msg],
            attachments: attachment_files(event)
          }
        end
      end

      private

      attr_reader :params

      def events
        @events ||= ActiveSupport::JSON.decode(params[:mandrill_events]).map do |event|
          event['msg'].with_indifferent_access
        end
      end

      def recipients(field, event)
        event[field].map { |recipient| full_email(recipient) }
      end

      def full_email(contact_info)
        email = contact_info[0]
        if contact_info[1]
          "#{contact_info[1]} <#{email}>"
        else
          email
        end
      end

      def attachment_files(event)
        attachments = event[:attachments] || Array.new
        attachments.map do |key, attachment|
          ActionDispatch::Http::UploadedFile.new({
            filename: attachment[:name],
            type: attachment[:type],
            tempfile: create_tempfile(attachment)
          })
        end
      end

      def create_tempfile(attachment)
        filename = attachment[:name]
        tempfile = Tempfile.new(filename, Dir::tmpdir, encoding: 'ascii-8bit')
        tempfile.write(Base64.decode64(attachment[:content]))
        tempfile.rewind
        tempfile
      end
    end
  end
end
