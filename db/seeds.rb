# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

aluno_repository = Academico::Infra::Aluno::Repositories::ActiveRecord.new
aluno_dto = Academico::App::Aluno::Matricular::Dto.new(cpf: "12345678912", nome: "Felipe", email: "felipe@gmail.com")

Academico::App::Aluno::Matricular::Create.new(aluno_repository:, publicador_de_evento: nil).call(aluno_dto:)
