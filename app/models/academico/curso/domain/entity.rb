module Academico
  module Curso
    module Domain
      class Entity < ApplicationRecord
        self.table_name = "academico_cursos"
      end
    end
  end
end
