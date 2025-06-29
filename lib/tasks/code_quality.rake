# frozen_string_literal: true

desc "Run all code quality checks"
task quality: %i(
  brakeman
  standard
  check_service_objects
  check_controller_size
  check_namespacing
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
        if current_method && method_line_count > 10
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

        if method_line_count > 10
          violations << {
            file: file,
            method: current_method,
            lines: method_line_count,
            line_number: line_number - method_line_count + 1,
          }
        end

        current_method = nil
        method_line_count = 0
      elsif current_method
        method_line_count += 1 unless stripped.empty? || stripped.start_with?("#")
      end
    end
  end

  if violations.any?
    puts "❌ Fat controller methods found (>10 lines):"
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
  puts "✅ Domain namespaces (Billing::, Schedule::)"
  puts "✅ POROs in app/models (80% target)"
  puts "✅ Thin controllers (<10 lines per action)"
  puts "✅ Hidden resources (controllers without AR models)"
  puts "❌ No service objects or command pattern"
  puts "❌ No technical pattern directories"
  puts "\nSee CODING_STANDARDS.md for full details"
end
