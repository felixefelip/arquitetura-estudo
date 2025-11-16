# rbs_inline: enabled

module Academico
  module Aluno
    class LogMatriculado
      # @rbs (payload: Hash[Symbol, untyped]) -> ::String
      def reage_ao(payload:)
        cpf_aluno = payload.fetch(:cpf_aluno)
        momento = payload.fetch(:momento)

        messagem = "Aluno com CPF #{cpf_aluno} foi matriculado na data #{momento}"

        Rails.logger.info messagem
        messagem
      end
    end
  end
end
