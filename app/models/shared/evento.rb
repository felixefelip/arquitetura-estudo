module Shared
  module Evento
    extend ActiveSupport::Concern

    included do
      def momento
        raise NotImplementedError
      end
    end
  end
end
