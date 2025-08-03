require 'English'
namespace :quality do
  desc "Run all code quality checks"
  task :check do
    puts "🔍 Running Code Quality Checks...\n\n"

    # Track overall success
    all_passed = true

    # 1. RuboCop - Style Guide
    puts "1️⃣  Running RuboCop (Style Guide)..."
    puts "=" * 50
    system("RAILS_ENV=development bundle exec rubocop")
    rubocop_success = $CHILD_STATUS.success?
    all_passed = false unless rubocop_success
    puts rubocop_success ? "✅ RuboCop: PASSED" : "❌ RuboCop: FAILED"
    puts "\n"

    # 2. Brakeman - Security Scanner
    puts "2️⃣  Running Brakeman (Security Scanner)..."
    puts "=" * 50
    system("bundle exec brakeman --no-pager")
    brakeman_success = $CHILD_STATUS.success?
    all_passed = false unless brakeman_success
    puts brakeman_success ? "✅ Brakeman: PASSED" : "❌ Brakeman: FAILED"
    puts "\n"

    # 3. Reek - Code Smell Detection
    puts "3️⃣  Running Reek (Code Smell Detection)..."
    puts "=" * 50
    system("bundle exec reek --no-documentation")
    reek_success = $CHILD_STATUS.success?
    all_passed = false unless reek_success
    puts reek_success ? "✅ Reek: PASSED" : "❌ Reek: FAILED"
    puts "\n"

    # 4. RSpec - Tests + Coverage
    puts "4️⃣  Running RSpec (Tests + Coverage)..."
    puts "=" * 50
    system("RAILS_ENV=test bundle exec rspec")
    rspec_success = $CHILD_STATUS.success?
    all_passed = false unless rspec_success
    puts rspec_success ? "✅ RSpec: PASSED" : "❌ RSpec: FAILED"
    puts "\n"

    # 5. Coding Standards - Our custom checks
    puts "5️⃣  Running Coding Standards Checks..."
    puts "=" * 50
    system("bundle exec rake coding_standards")
    coding_standards_success = $CHILD_STATUS.success?
    all_passed = false unless coding_standards_success
    puts coding_standards_success ? "✅ Coding Standards: PASSED" : "❌ Coding Standards: FAILED"
    puts "\n"

    # Summary
    puts "🏁 Quality Check Summary:"
    puts "=" * 50
    puts "RuboCop (Style):     #{rubocop_success ? '✅ PASSED' : '❌ FAILED'}"
    puts "Brakeman (Security): #{brakeman_success ? '✅ PASSED' : '❌ FAILED'}"
    puts "Reek (Code Smells):  #{reek_success ? '✅ PASSED' : '❌ FAILED'}"
    puts "RSpec (Tests):       #{rspec_success ? '✅ PASSED' : '❌ FAILED'}"
    puts "Coding Standards:    #{coding_standards_success ? '✅ PASSED' : '❌ FAILED'}"
    puts "\n"

    if all_passed
      puts "🎉 All quality checks PASSED! 🚀"
      exit 0
    else
      puts "💥 Some quality checks FAILED. Please fix issues above."
      exit 1
    end
  end

  desc "Run RuboCop style checks"
  task :style do
    puts "🎨 Running RuboCop (Style Guide)..."
    system("RAILS_ENV=development bundle exec rubocop") || exit(1)
  end

  desc "Run Brakeman security scan"
  task :security do
    puts "🔒 Running Brakeman (Security Scanner)..."
    system("bundle exec brakeman --no-pager") || exit(1)
  end

  desc "Run Reek code smell detection"
  task :smells do
    puts "👃 Running Reek (Code Smell Detection)..."
    system("bundle exec reek --no-documentation") || exit(1)
  end

  desc "Run tests with coverage"
  task :test do
    puts "🧪 Running RSpec (Tests + Coverage)..."
    system("RAILS_ENV=test bundle exec rspec") || exit(1)
  end

  desc "Auto-fix RuboCop style issues where possible"
  task :fix do
    puts "🔧 Auto-fixing RuboCop issues..."
    system("RAILS_ENV=development bundle exec rubocop --autocorrect") || exit(1)
  end
end
