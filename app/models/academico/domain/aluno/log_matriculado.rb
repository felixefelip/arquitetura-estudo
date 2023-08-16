module Academico
  module Domain
    module Aluno
      class LogMatriculado
        include ::Shared::Evento::Ouvinte

        def reage_ao(evento_aluno_matriculado:)
          Rails.logger.info "Aluno com CPF #{evento_aluno_matriculado.cpf_aluno}
					                   foi matriculado na data #{evento_aluno_matriculado.momento}"
        end

        def sabe_processar?(evento:)
          evento.is_a? Matriculado
        end
      end
    end
  end
end
