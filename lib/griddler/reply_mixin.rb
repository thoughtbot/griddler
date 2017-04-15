module Griddler
  module ReplyMixin
    def reply(email, headers={}, &block)
      reply = Reply.new(email)
      mail(reply.headers.merge(headers), &block)
    end

    private

    class Reply
      def initialize(email)
        @email = email
      end

      def headers
        { to: reply_address, subject: subject }.merge(identity_headers)
      end

      private

      attr_reader :email

      def reply_address
        email.headers['Reply-To'] || email.from
      end

      def subject
        "Re: #{original_subject}"
      end

      def original_subject
        email.subject.sub(/^Re:\s+/, '')
      end

      def identity_headers
        if parent_has_message_id?
          { 'In-Reply-To' => parent_message_id, 'References' => references }
        else
          {}
        end
      end

      def parent_has_message_id?
        parent_message_id.present?
      end

      def references
        [parent_references, parent_message_id].compact.join(' ')
      end

      def parent_message_id
        email.headers['Message-ID']
      end

      def parent_references
        email.headers['References'] || parent_single_in_reply_to
      end

      def parent_single_in_reply_to
        unless parent_in_reply_to =~ /\s/
          parent_in_reply_to
        end
      end

      def parent_in_reply_to
        email.headers['In-Reply-To']
      end
    end
  end
end
