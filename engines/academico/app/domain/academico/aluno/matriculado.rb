module Academico
  module Aluno
    class Matriculado
      attr_reader :momento, :cpf_aluno, :name

      def initialize(cpf_aluno:)
        @momento = DateTime.current
        @cpf_aluno = cpf_aluno
        @name = "aluno_matriculado"
      end
    end
  end
end
