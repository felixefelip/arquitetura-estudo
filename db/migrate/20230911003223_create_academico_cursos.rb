class CreateAcademicoCursos < ActiveRecord::Migration[7.0]
  def change
    create_table :academico_cursos do |t|
      t.string :titulo
      t.string :url
      t.string :icone
      t.boolean :assitido

      t.timestamps
    end
  end
end
