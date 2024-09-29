module Academico
  class ApplicationMailer < ActionMailer::Base
    default from: "from@example.com"
    layout "mailer"

    self.view_paths = Academico::Engine.root.join("app", "infra", "http", "views")
  end
end
