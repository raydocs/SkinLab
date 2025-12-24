#!/usr/bin/env ruby

require 'xcodeproj'

project_path = '/Users/ruirui/Code/Ai_Code/SkinLab/SkinLab.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'SkinLab' }

# Files to add (relative to project root)
files_to_add = [
  # Core/Utils
  { path: 'SkinLab/Core/Utils/UserHistoryStore.swift', group: 'Core/Utils' },

  # Features/Tracking/Models
  { path: 'SkinLab/Features/Tracking/Models/IngredientExposureRecord.swift', group: 'Features/Tracking/Models' },

  # Features/Profile/Models
  { path: 'SkinLab/Features/Profile/Models/UserIngredientPreference.swift', group: 'Features/Profile/Models' },
]

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

added_count = 0
skipped_count = 0

files_to_add.each do |file_info|
  file_path = File.join('/Users/ruirui/Code/Ai_Code/SkinLab', file_info[:path])

  # Check if file exists
  unless File.exist?(file_path)
    puts "⚠️  File not found: #{file_info[:path]}"
    next
  end

  # Check if file is already in project
  existing_file = project.files.find { |f| f.real_path.to_s == file_path }
  if existing_file
    puts "⏭️  Already in project: #{file_info[:path]}"
    skipped_count += 1
    next
  end

  # Find or create the group
  group_path = file_info[:group].split('/')
  group = find_or_create_group(project, group_path)

  # Add file to group
  file_ref = group.new_file(file_path)

  # Add to target's sources build phase (only for .swift files)
  if file_path.end_with?('.swift')
    target.source_build_phase.add_file_reference(file_ref)
  end

  puts "✅ Added: #{file_info[:path]}"
  added_count += 1
end

# Save the project
project.save

puts "\n📊 Summary:"
puts "   ✅ Added: #{added_count} files"
puts "   ⏭️  Skipped: #{skipped_count} files (already in project)"
puts "\n✨ Project file updated successfully!"
