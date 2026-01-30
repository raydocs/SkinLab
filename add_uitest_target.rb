#!/usr/bin/env ruby
# Add SkinLabUITests target to the Xcode project
# Usage: ruby add_uitest_target.rb

require 'xcodeproj'

PROJECT_PATH = 'SkinLab.xcodeproj'
UI_TEST_TARGET_NAME = 'SkinLabUITests'
MAIN_TARGET_NAME = 'SkinLab'

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Check if UI test target already exists
if project.targets.find { |t| t.name == UI_TEST_TARGET_NAME }
  puts "✅ #{UI_TEST_TARGET_NAME} target already exists"
  exit 0
end

puts "📦 Adding #{UI_TEST_TARGET_NAME} target..."

# Find main target
main_target = project.targets.find { |t| t.name == MAIN_TARGET_NAME }
unless main_target
  puts "❌ Could not find main target: #{MAIN_TARGET_NAME}"
  exit 1
end

# Create UI test target
ui_test_target = project.new_target(:ui_test_bundle, UI_TEST_TARGET_NAME, :ios, '17.0')

# Configure build settings
ui_test_target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'SkinLabUITests/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.skinlab.app.uitests'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['TEST_TARGET_NAME'] = MAIN_TARGET_NAME
  config.build_settings['BUNDLE_LOADER'] = ''
end

# Add dependency on main target
ui_test_target.add_dependency(main_target)

# Create group for UI test files
ui_tests_group = project.main_group.find_subpath('SkinLabUITests', true)
ui_tests_group.set_source_tree('<group>')
ui_tests_group.set_path('SkinLabUITests')

# Add Swift files to target
swift_files = Dir.glob('SkinLabUITests/*.swift')
swift_files.each do |file_path|
  file_name = File.basename(file_path)
  file_ref = ui_tests_group.new_reference(file_name)
  ui_test_target.source_build_phase.add_file_reference(file_ref)
  puts "   Added: #{file_name}"
end

# Add Info.plist reference (but not to build phase)
info_plist = ui_tests_group.new_reference('Info.plist')

# Save project
project.save

puts "✅ Successfully added #{UI_TEST_TARGET_NAME} target"
puts ""
puts "Next steps:"
puts "1. Open Xcode and verify the target was added correctly"
puts "2. Select the SkinLabUITests scheme to run UI tests"
