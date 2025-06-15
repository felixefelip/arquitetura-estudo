module Academico
  module Aluno
    class Email
      def initialize(endereco:)
        raise ArgumentError unless endereco_valido?

        self.endereco = endereco
      end

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
