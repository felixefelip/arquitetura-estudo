module Academico
  module Aluno
    class Matricular
      class Dto
        attr_reader :cpf, :email, :nome, :senha

        def initialize(cpf:, nome:, email:)
          self.cpf = cpf
          self.nome = nome
          self.email = email
        end

        private

        attr_writer :cpf, :email, :nome, :senha
      end
    end
  end
end
