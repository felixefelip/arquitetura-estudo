module Academico
  module Domain
    module Curso
      class Entity < ApplicationRecord
        self.table_name = "academico_cursos"
      end
    end
  end
end
