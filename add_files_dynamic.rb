#!/usr/bin/env ruby

require 'xcodeproj'

project_path = '/Users/ruirui/Code/Ai_Code/SkinLab/SkinLab.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'SkinLab' }

# Get files from command line arguments
if ARGV.empty?
  puts "Usage: ruby add_files_dynamic.rb <file1.swift> <file2.swift> ..."
  exit 1
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

added_count = 0
skipped_count = 0

ARGV.each do |relative_path|
  file_path = File.join('/Users/ruirui/Code/Ai_Code/SkinLab', relative_path)

  # Check if file exists
  unless File.exist?(file_path)
    puts "⚠️  File not found: #{relative_path}"
    next
  end

  # Check if file is already in project
  existing_file = project.files.find { |f| f.real_path.to_s == file_path }
  if existing_file
    puts "⏭️  Already in project: #{relative_path}"
    skipped_count += 1
    next
  end

  # Extract group path from file path
  # e.g., "SkinLab/Features/Tracking/Models/File.swift" -> ["SkinLab", "Features", "Tracking", "Models"]
  path_parts = relative_path.split('/')
  group_parts = path_parts[0...-1]  # All but the last (filename)

  # Find or create the group
  group = find_or_create_group(project, group_parts)

  # Add file to group
  file_ref = group.new_file(file_path)

  # Add to target's sources build phase (only for .swift files)
  if file_path.end_with?('.swift')
    target.source_build_phase.add_file_reference(file_ref)
  end

  puts "✅ Added: #{relative_path}"
  added_count += 1
end

# Save the project
project.save

puts "\n📊 Summary:"
puts "   ✅ Added: #{added_count} files"
puts "   ⏭️  Skipped: #{skipped_count} files (already in project)"
puts "\n✨ Project file updated successfully!"
