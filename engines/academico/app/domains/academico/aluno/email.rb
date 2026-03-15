# rbs_inline: enabled

module Academico
  module Aluno
    class Email
      def initialize(endereco:)
        raise ArgumentError unless endereco_valido?

        self.endereco = endereco
      end

      #: -> ::String
      def to_s
        endereco
      end

      private

      attr_accessor :endereco

      def endereco_valido?
        true
      end
    end
  end
end
