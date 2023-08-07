module Academico
  module Infra
    module Aluno
      module Repositories
        class ActiveRecord < ApplicationRecord
          include ::Academico::Domain::Aluno::Repository

          self.table_name = 'academico_alunos'

          def adicionar(aluno)
            self.class.create!(nome: aluno.nome, email: aluno.email, cpf: aluno.cpf, senha: aluno.senha)
          end

          def buscar_por_cpf(cpf)
            self.class.find_by(cpf:)
          end

          def buscar_todos
            self.class.all
          end
        end
      end
    end
  end
end
