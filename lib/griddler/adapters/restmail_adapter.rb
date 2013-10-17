module Griddler
  module Adapters
    class RestmailAdapter
      def initialize(params)
        @params = params
      end

      def self.normalize_params(params)
        adapter = new(params)
        adapter.normalize_params
      end

      #{ "from" : "bla@blub", "to" : "foo@bar.com", "subject" : "subject", "plain" : "fsdjfdsf jsdfdsjf"}
      def normalize_params
        
        puts params
        
        {
          to: params[:to].split(','),
          from: params[:from],
          subject: params[:subject],
          text: params[:plain],
          attachments: nil,
        }
      end

      private

      attr_reader :params

    end
  end
end
