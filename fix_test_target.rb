#!/usr/bin/env ruby

require 'xcodeproj'

project_path = '/Users/ruirui/Code/Ai_Code/SkinLab/SkinLab.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find test target
test_target = project.targets.find { |t| t.name == 'SkinLabTests' }

if test_target
  puts "Fixing SkinLabTests target configuration..."

  test_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_NAME'] = 'SkinLabTests'
    config.build_settings['PRODUCT_MODULE_NAME'] = 'SkinLabTests'
    config.build_settings['WRAPPER_EXTENSION'] = 'xctest'
    config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@loader_path/Frameworks']
    config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
    config.build_settings['SWIFT_EMIT_LOC_STRINGS'] = 'NO'
  end

  project.save
  puts "✅ Fixed SkinLabTests target"
else
  puts "❌ SkinLabTests target not found"
end
