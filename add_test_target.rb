#!/usr/bin/env ruby

require 'xcodeproj'

project_path = '/Users/ruirui/Code/Ai_Code/SkinLab/SkinLab.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Check if test target already exists
test_target = project.targets.find { |t| t.name == 'SkinLabTests' }

if test_target.nil?
  puts "Creating SkinLabTests target..."

  # Get the main target for reference
  main_target = project.targets.find { |t| t.name == 'SkinLab' }

  # Create test target
  test_target = project.new_target(:unit_test_bundle, 'SkinLabTests', :ios, '17.0')

  # Add dependency on main target
  test_target.add_dependency(main_target)

  # Set up build settings
  test_target.build_configurations.each do |config|
    config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
    config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/SkinLab.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/SkinLab'
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.skinlab.SkinLabTests'
    config.build_settings['INFOPLIST_FILE'] = ''
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['SWIFT_VERSION'] = '5.0'
  end

  puts "✅ Created SkinLabTests target"
else
  puts "ℹ️  SkinLabTests target already exists"
end

# Helper function to find or create group
def find_or_create_group(project, path_components)
  current_group = project.main_group

  path_components.each do |component|
    next_group = current_group.groups.find { |g| g.name == component || g.path == component }

    if next_group.nil?
      next_group = current_group.new_group(component, component)
    end

    current_group = next_group
  end

  current_group
end

# Find all test files
test_files = Dir.glob('/Users/ruirui/Code/Ai_Code/SkinLab/SkinLabTests/**/*.swift')

puts "\nAdding test files to project..."

added_count = 0
skipped_count = 0

test_files.each do |file_path|
  # Get relative path
  relative_path = file_path.sub('/Users/ruirui/Code/Ai_Code/SkinLab/', '')

  # Check if file is already in project
  existing_file = project.files.find { |f| f.real_path.to_s == file_path }
  if existing_file
    # Check if it's in the test target
    unless test_target.source_build_phase.files_references.include?(existing_file)
      test_target.source_build_phase.add_file_reference(existing_file)
      puts "🔗 Linked to target: #{relative_path}"
    else
      puts "⏭️  Already in project: #{relative_path}"
      skipped_count += 1
    end
    next
  end

  # Extract group path from file path
  path_parts = relative_path.split('/')
  group_parts = path_parts[0...-1]

  # Find or create the group
  group = find_or_create_group(project, group_parts)

  # Add file to group
  file_ref = group.new_file(file_path)

  # Add to test target's sources build phase
  test_target.source_build_phase.add_file_reference(file_ref)

  puts "✅ Added: #{relative_path}"
  added_count += 1
end

# Save the project
project.save

puts "\n📊 Summary:"
puts "   ✅ Added: #{added_count} files"
puts "   ⏭️  Skipped: #{skipped_count} files (already in project)"
puts "\n✨ Project file updated successfully!"
