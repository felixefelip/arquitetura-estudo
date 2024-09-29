module Academico
  class Engine < ::Rails::Engine
    config.autoload_paths << "#{Academico::Engine.root}/app/infra/http/controllers"
    config.autoload_paths << "#{Academico::Engine.root}/app/infra/http/helpers"
    config.autoload_paths << "#{Academico::Engine.root}/app/infra/http/views"
    config.autoload_paths << "#{Academico::Engine.root}/app/infra/repositories"
    config.autoload_paths << "#{Academico::Engine.root}/app/application"
    config.autoload_paths << "#{Academico::Engine.root}/app/domain"
    isolate_namespace Academico
  end
end
