# frozen_string_literal: true

desc "Run coding standards checks"
task coding_standards: %i(
  check_service_objects
  check_controller_size
  check_namespacing
  standards_summary
)

desc "Check for service objects anti-pattern"
task :check_service_objects do
  puts "🔍 Checking for service objects..."

  service_files = Dir.glob("app/services/**/*.rb")
  if service_files.any?
    puts "❌ Service objects found (use POROs in app/models instead):"
    service_files.each { |f| puts "  #{f}" }
    exit 1
  end

  # Check for .call pattern in models
  call_pattern_files = []
  Dir.glob("app/models/**/*.rb").each do |file|
    content = File.read(file)
    if content.match?(/def (self\.)?call/)
      call_pattern_files << file
    end
  end

  if call_pattern_files.any?
    puts "⚠️  Command pattern (.call) found in models:"
    call_pattern_files.each { |f| puts "  #{f}" }
    puts "Consider using descriptive method names instead"
  end

  puts "✅ No service objects found"
end

desc "Check controller sizes (thin controllers)"
task :check_controller_size do
  puts "🔍 Checking controller sizes..."

  violations = []

  Dir.glob("app/controllers/**/*.rb").each do |file|
    lines = File.readlines(file)
    current_method = nil
    method_line_count = 0
    line_number = 0

    lines.each do |line|
      line_number += 1
      stripped = line.strip

      # Start of method
      if stripped.match?(/^def\s+\w+/)
        # Save previous method if it was too long
        if current_method && method_line_count > 15
          violations << {
            file: file,
            method: current_method,
            lines: method_line_count,
            line_number: line_number - method_line_count,
          }
        end

        current_method = stripped.match(/^def\s+(\w+)/)[1]
        method_line_count = 1
      elsif stripped == "end" && current_method
        # End of method - check if this closes our method
        method_line_count += 1

        if method_line_count > 15
          violations << {
            file: file,
            method: current_method,
            lines: method_line_count,
            line_number: line_number - method_line_count + 1,
          }
        end

        current_method = nil
        method_line_count = 0
      elsif current_method && !stripped.empty? && !stripped.start_with?("#")
        method_line_count += 1
      end
    end
  end

  if violations.any?
    puts "❌ Fat controller methods found (>15 lines):"
    violations.each do |v|
      puts "  #{v[:file]}:#{v[:line_number]} - #{v[:method]} (#{v[:lines]} lines)"
    end
    puts "\nMove business logic to models (POROs)"
    exit 1
  end

  puts "✅ All controllers are thin"
end

desc "Check for proper domain namespacing"
task :check_namespacing do
  puts "🔍 Checking namespacing patterns..."

  # Check for technical pattern directories (anti-pattern)
  bad_dirs = %w(
    app/services
    app/decorators
    app/builders
    app/commands
    app/queries
    app/interactors
  )

  found_bad_dirs = bad_dirs.select { |dir| Dir.exist?(dir) }

  if found_bad_dirs.any?
    puts "❌ Technical pattern directories found:"
    found_bad_dirs.each { |dir| puts "  #{dir}/" }
    puts "\nOrganize by domain meaning instead (Billing::, Schedule::)"
    exit 1
  end

  # Check for controllers outside of namespaces (beyond basic Rails controllers)
  non_namespaced_controllers = Dir.glob("app/controllers/*.rb").reject do |file|
    file.include?("application_controller") ||
    file.include?("home_controller") ||
    file.match?(/_(omniauth_callbacks|registrations|sessions|passwords|confirmations|unlocks)_controller\.rb$/)
  end

  if non_namespaced_controllers.count > 3 # Allow some basic controllers
    puts "⚠️  Consider using domain namespaces for controllers:"
    non_namespaced_controllers.each { |f| puts "  #{f}" }
    puts "\nExample: move LeaguesController to Leagues::ManagementController"
  end

  puts "✅ Namespacing looks good"
end

desc "Show coding standards summary"
task :standards_summary do
  puts "\n📋 CODING STANDARDS SUMMARY"
  puts "=" * 50

  # Check for service objects
  service_files = Dir.glob("app/services/**/*.rb")
  service_objects_status = service_files.any? ? "❌" : "✅"
  puts "#{service_objects_status} No service objects or command pattern"

  # Check for technical pattern directories
  bad_dirs = %w(
    app/services
    app/decorators
    app/builders
    app/commands
    app/queries
    app/interactors
  )
  found_bad_dirs = bad_dirs.select { |dir| Dir.exist?(dir) }
  technical_patterns_status = found_bad_dirs.any? ? "❌" : "✅"
  puts "#{technical_patterns_status} No technical pattern directories"

  # Check controller sizes
  violations = []
  Dir.glob("app/controllers/**/*.rb").each do |file|
    lines = File.readlines(file)
    current_method = nil
    method_line_count = 0

    lines.each do |line|
      stripped = line.strip

      if stripped.match?(/^def\s+\w+/)
        if current_method && method_line_count > 15
          violations << { file: file, method: current_method }
        end
        current_method = stripped.match(/^def\s+(\w+)/)[1]
        method_line_count = 1
      elsif stripped == "end" && current_method
        method_line_count += 1
        if method_line_count > 15
          violations << { file: file, method: current_method }
        end
        current_method = nil
        method_line_count = 0
      elsif current_method && !stripped.empty? && !stripped.start_with?("#")
        method_line_count += 1
      end
    end
  end
  thin_controllers_status = violations.any? ? "❌" : "✅"
  puts "#{thin_controllers_status} Thin controllers (<15 lines per action)"

  # Check PORO vs ActiveRecord ratio
  ar_models = Dir.glob("app/models/**/*.rb").select do |file|
    content = File.read(file)
    content.match?(/class\s+\w+\s*<\s*ApplicationRecord/)
  end.count

  total_models = Dir.glob("app/models/**/*.rb").reject { |f| f.include?("application_record") }.count
  poro_models = total_models - ar_models
  poro_ratio = total_models > 0 ? poro_models.to_f / total_models : 0
  poro_status = poro_ratio >= 0.5 ? "✅" : "❌"
  puts "#{poro_status} POROs in app/models (50% target - currently #{(poro_ratio * 100).round(1)}% - #{poro_models}/#{total_models})"

  # Domain namespaces (simplified check)
  namespaced_controllers = Dir.glob("app/controllers/**/*.rb").select do |file|
    file.include?("/") && file.exclude?("application_controller")
  end.count
  namespaces_status = namespaced_controllers > 0 ? "✅" : "⚠️"
  puts "#{namespaces_status} Domain namespaces (Billing::, Schedule::)"

  puts "\nSee CODING_STANDARDS.md for full details"
end
