module Academico
  module Infra
    module Aluno
      module Repositories
        module ActiveRecord
          class Impl
            include ::Academico::Domain::Aluno::Repository

            def initialize
              self.record = Record.new
            end

            def adicionar(aluno)
              Record.create(nome: aluno.nome, email: aluno.email, cpf: aluno.cpf, senha: aluno.senha)
            end

            def buscar_por_cpf(cpf)
              Record.find_by(cpf:)
            end

            def buscar_todos
              Record.all
            end

            private

            attr_accessor :record
          end
        end
      end
    end
  end
end