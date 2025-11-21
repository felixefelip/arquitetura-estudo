# rbs_inline: enabled

module Academico
  module Aluno
    class Email
      #: (endereco: ::String) -> void
      def initialize(endereco:)
        raise ArgumentError unless endereco_valido?

        self.endereco = endereco
      end

      #: -> ::String
      def to_s
        endereco
      end

      private

      attr_accessor :endereco #: String

      #: -> bool
      def endereco_valido?
        true
      end
    end
  end
end
