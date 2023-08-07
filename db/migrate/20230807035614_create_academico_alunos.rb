class CreateAcademicoAlunos < ActiveRecord::Migration[7.0]
  def change
    create_table :academico_alunos do |t|
      t.string :cpf, null: false
      t.string :email, null: false
      t.string :nome, null: false
      t.string :senha

      t.timestamps
    end
  end
end
