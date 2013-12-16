module Griddler
  module Adapters
    class SimplemailAdapter
      def initialize(params)
        @params = params
      end

      def self.normalize_params(params)
        adapter = new(params)
        adapter.normalize_params
      end

      # As JSON message in RAILS
      #{ "from" : "foo@bar.com",
      #  "to" : "alice@example.com,bob@example.com",
      #  "subject" : "test email",
      #  "text" : "Howdy ! This is an email sent to RAILS !" }
      #
      # or HTTP post from e.g. a form
      
      def normalize_params
        {
          from: params[:from],
          to: params[:to].split(','),
          subject: params[:subject],
          text: params[:text],
          attachments: [],
          html: nil
        }
      end

      private

      attr_reader :params

    end
  end
end
