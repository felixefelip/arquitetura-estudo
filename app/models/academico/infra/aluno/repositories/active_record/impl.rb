module Academico
  module Infra
    module Aluno
      module Repositories
        module ActiveRecord
          class Impl
            def adicionar(aluno:)
              Record.create(nome: aluno.nome, email: aluno.email, cpf: aluno.cpf, senha: aluno.senha)
            end

            def buscar_por_cpf(cpf)
              record = Record.find_by(cpf:)

              raise StandardError if record.nil?

              Academico::Domain::Aluno::Entity.new(nome: record.nome, email: record.email, cpf: record.cpf)
            end

            def buscar_todos
              Record.all.map do |record|
                Academico::Domain::Aluno::Entity.new(nome: record.nome, email: record.email, cpf: record.cpf)
              end
            end
          end
        end
      end
    end
  end
end
