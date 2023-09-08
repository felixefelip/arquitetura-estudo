module Academico
  module Domain
    module Aluno
      class LogMatriculado < ::Shared::Domain::Evento::Ouvinte
        def reage_ao(evento:)
          messagem = "Aluno com CPF #{evento.cpf_aluno}
					                   foi matriculado na data #{evento.momento}"

          Rails.logger.info messagem
          messagem
        end

        def sabe_processar?(evento:)
          evento.instance_of?(Matriculado)
        end
      end
    end
  end
end
