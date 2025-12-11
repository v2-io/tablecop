# frozen_string_literal: true

require "minitest/autorun"
require "rubocop"

require_relative "../lib/tablecop"

module CopHelper
  def cop_class
    raise NotImplementedError, "Define cop_class in your test"
  end

  def cop_config
    {}
  end

  def config
    RuboCop::Config.new(
      "Layout/LineLength" => { "Max" => 80 },
      cop_class.cop_name => cop_config
    )
  end

  def parse_source(source)
    RuboCop::ProcessedSource.new(source, 3.3)
  end

  # Run the cop and collect offenses
  def investigate(source)
    processed_source = parse_source(source)
    cop = cop_class.new(config)

    team = RuboCop::Cop::Team.new([cop], config)
    report = team.investigate(processed_source)
    report.offenses
  end

  # Run autocorrect and return the corrected source
  def autocorrect(source)
    processed_source = parse_source(source)
    cop = cop_class.new(config)

    team = RuboCop::Cop::Team.new([cop], config, autocorrect: true)
    report = team.investigate(processed_source)

    # Get the corrected source from the corrector
    corrector = RuboCop::Cop::Corrector.new(processed_source)

    report.offenses.each do |offense|
      next unless offense.corrector

      corrector.merge!(offense.corrector)
    end

    corrector.rewrite
  end

  def assert_correction(source, expected)
    corrected = autocorrect(source)
    assert_equal expected, corrected, "Autocorrection did not produce expected output"
  end

  def assert_no_offenses(source)
    offenses = investigate(source)
    offense_msgs = offenses.map(&:message).join(", ")
    assert_empty offenses, "Expected no offenses but got: #{offense_msgs}"
  end

  def assert_offense(source, message_pattern = nil)
    offenses = investigate(source)
    refute_empty offenses, "Expected offenses but got none"

    if message_pattern
      assert offenses.any? { |o| o.message.include?(message_pattern) },
             "No offense matched '#{message_pattern}'. Got: #{offenses.map(&:message)}"
    end
  end
end
