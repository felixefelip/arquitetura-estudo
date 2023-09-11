# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# aluno_repository = Academico::Aluno::Infra::Repositories::ActiveRecord::Impl.new
# aluno_dto = Academico::Aluno::App::Matricular::Dto.new(cpf: "12345678912", nome: "Felipe", email: "felipe@gmail.com")

# Academico::Aluno::App::Matricular::Create.new(aluno_repository:, publicador_de_evento: nil).call(aluno_dto:)


cursos = [
	[
			'titulo' => 'Microsserviços: Padrões de projeto',
			'url' => 'https://cursos.alura.com.br/course/microsservicos-padroes-projeto',
			'icone' => 'https://www.alura.com.br/assets/api/cursos/microsservicos-padroes-projeto.svg',
	],
	[

			'titulo' => 'Mais sobre microsserviços',
			'url' => 'https://cursos.alura.com.br/course/fundamentos-microsservicos-aprofundando-conceitos',
			'icone' => 'https://www.alura.com.br/assets/api/cursos/fundamentos-microsservicos-aprofundando-conceitos.svg',
	],
	[

			'titulo' => 'Integração contínua',
			'url' => 'https://cursos.alura.com.br/course/desenvolvimento-software-integracao-continua',
			'icone' => 'https://www.alura.com.br/assets/api/cursos/desenvolvimento-software-integracao-continua.svg',
	],
	[

			'titulo' => 'Entrega contínua',
			'url' => 'https://cursos.alura.com.br/course/entrega-continua-confiabilidade-qualidade',
			'icone' => 'https://www.alura.com.br/assets/api/cursos/entrega-continua-confiabilidade-qualidade.svg',
	],
	[

			'titulo' => '12-Factor Apps',
			'url' => 'https://cursos.alura.com.br/course/the-twelve-factor-app',
			'icone' => 'https://www.alura.com.br/assets/api/cursos/the-twelve-factor-app.svg',
	],
	[

			'titulo' => 'Docker',
			'url' => 'https://cursos.alura.com.br/course/docker-e-docker-compose',
			'icone' => 'https://www.alura.com.br/assets/api/cursos/docker-e-docker-compose.svg',
	],
	[

			'titulo' => 'Kubernetes',
			'url' => 'https://cursos.alura.com.br/course/kubernetes-pods-services-configmap',
			'icone' => 'https://www.alura.com.br/assets/api/cursos/kubernetes-pods-services-configmap.svg',
	],
	[

			'titulo' => 'Nginx 1',
			'url' => 'https://cursos.alura.com.br/course/nginx-servidor-web-proxy-reverso-api-gateway',
			'icone' => 'https://www.alura.com.br/assets/api/cursos/nginx-servidor-web-proxy-reverso-api-gateway.svg',
	],
	[

			'titulo' => 'Nginx 2',
			'url' => 'https://cursos.alura.com.br/course/nginx-parte-2-performance-fastcgi-https',
			'icone' => 'https://www.alura.com.br/assets/api/cursos/nginx-parte-2-performance-fastcgi-https.svg',
	],
];


cursos.each do |curso|
	Academico::Domain::Curso::Entity.create!(curso)
end
