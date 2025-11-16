# rbs_inline: enabled

module Academico
  module Aluno
    class Email
      # @rbs (endereco: ::String) -> void
      def initialize(endereco:)
        raise ArgumentError unless endereco_valido?

        self.endereco = endereco
      end

      # @rbs () -> ::String
      def to_s
        endereco
      end

      private

      attr_accessor :endereco #: String

      # @rbs () -> bool
      def endereco_valido?
        true
      end
    end
  end
end
