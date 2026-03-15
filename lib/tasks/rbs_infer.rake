require_relative "../../lib/rbs_usage_analyzer"

namespace :rbs do
  desc "Infer RBS types from call-site usage analysis (Prism-based)"
  task :infer, [:class_name] => :environment do |_t, args|
    class_name = args[:class_name]

    unless class_name
      puts "Uso: rake rbs:infer[Finance::Client::Enroll]"
      exit 1
    end

    source_files = Dir[
      "app/**/*.rb",
      "engines/**/*.rb",
      "lib/**/*.rb"
    ]

    analyzer = RbsUsageAnalyzer.new(
      target_class: class_name,
      source_files: source_files
    )

    rbs = analyzer.generate_rbs

    if rbs
      puts rbs
    else
      puts "Classe #{class_name} não encontrada ou nenhum membro detectado."
    end
  end

  desc "Infer RBS and write to sig/ directory"
  task :infer_write, [:class_name] => :environment do |_t, args|
    class_name = args[:class_name]

    unless class_name
      puts "Uso: rake rbs:infer_write[Finance::Client::Enroll]"
      exit 1
    end

    source_files = Dir[
      "app/**/*.rb",
      "engines/**/*.rb",
      "lib/**/*.rb"
    ]

    analyzer = RbsUsageAnalyzer.new(
      target_class: class_name,
      source_files: source_files
    )

    rbs = analyzer.generate_rbs

    if rbs
      path_parts = class_name.split("::").map { |p| p.gsub(/([a-z])([A-Z])/, '\1_\2').downcase }
      output_path = File.join("sig", "generated", *path_parts) + ".rbs"

      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, rbs + "\n")
      puts "RBS escrito em: #{output_path}"
      puts rbs
    else
      puts "Classe #{class_name} não encontrada ou nenhum membro detectado."
    end
  end
end
