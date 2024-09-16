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
              record = Record.find_by(cpf: cpf.to_s)

              raise StandardError if record.nil?

              aluno = Academico::Domain::Aluno::Entity.new(nome: record.nome, email: record.email, cpf: record.cpf)

              record.telefones.each do |telefone|
                ddd = telefone.ddd
                numero = telefone.numero

                next if ddd.nil? || numero.nil?

                aluno.adicionar_telefone(ddd:, numero:)
              end

              aluno
            end

            def buscar_por_email(email)
              record = Record.find_by(email: email.to_s)

              raise StandardError if record.nil?

              aluno = Academico::Domain::Aluno::Entity.new(nome: record.nome, email: record.email, cpf: record.cpf)

              record.telefones.each do |telefone|
                ddd = telefone.ddd
                numero = telefone.numero

                next if ddd.nil? || numero.nil?

                aluno.adicionar_telefone(ddd:, numero:)
              end

              aluno
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
