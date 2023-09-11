module Academico
  module Aluno
    module Domain
      class Matriculado
        attr_reader :momento, :cpf_aluno

        def initialize(cpf_aluno:)
          @momento = DateTime.current
          @cpf_aluno = cpf_aluno
        end
      end
    end
  end
end
