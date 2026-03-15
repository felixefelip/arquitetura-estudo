.PHONY: rbs test steep lint all clean

# Generate RBS type signatures from inline annotations
rbs-i:
	bundle exec rbs-inline lib/ --output

# Run tests
test:
	bundle exec rspec

# Run Steep type checker
steep:
	bundle exec steep check

# Run RuboCop linter
lint:
	bundle exec rubocop

# Generate RBS then run Steep
typecheck: rbs steep

# Run everything: rbs, steep, tests, lint
all: rbs steep test lint

run-game:
	ruby main.rb

run-map-editor:
	ruby map_editor.rb
