# rbs_inline: enabled

module Academico
  module Aluno
    class Telefone
      attr_reader :ddd, :numero #: String

      # @rbs (ddd: ::String, numero: ::String) -> void
      def initialize(ddd:, numero:)
        self.ddd = ddd
        self.numero = numero
      end

      # @rbs () -> ::String
      def to_s
        "(#{ddd}) #{numero}"
      end

      private

      attr_writer :ddd, :numero #: String
    end
  end
end
