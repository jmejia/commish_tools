# View helper methods for draft grade display
module DraftGradesHelper
  GRADE_COLOR_CLASSES = {
    excellent: 'text-green-600 bg-green-50',
    good: 'text-blue-600 bg-blue-50',
    average: 'text-yellow-600 bg-yellow-50',
    below_average: 'text-orange-600 bg-orange-50',
    failing: 'text-red-600 bg-red-50',
  }.freeze

  def grade_color_class(draft_grade)
    GRADE_COLOR_CLASSES[draft_grade.grade_category] || 'text-gray-600 bg-gray-50'
  end

  POSITION_GRADE_COLORS = {
    'A' => 'text-green-600',
    'B' => 'text-blue-600',
    'C' => 'text-yellow-600',
    'D' => 'text-orange-600',
    'F' => 'text-red-600'
  }.freeze

  def position_grade_color(grade)
    POSITION_GRADE_COLORS[grade] || 'text-gray-600'
  end

  def format_playoff_probability(probability)
    "#{(probability * 100).round}%"
  end

  def format_projected_points(points)
    number_with_delimiter(points.round)
  end

  def draft_status_badge(draft)
    case draft.status
    when 'completed'
      content_tag :span, 'Completed',
                  class: 'inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800'
    when 'in_progress'
      content_tag :span, 'In Progress',
                  class: 'inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800'
    else
      content_tag :span, draft.status.humanize,
                  class: 'inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800'
    end
  end

  def grade_calculation_status(draft)
    if draft.grades_calculated?
      content_tag :span, 'Grades Ready',
                  class: 'text-green-600 text-sm'
    else
      content_tag :span, 'Calculating...',
                  class: 'text-yellow-600 text-sm animate-pulse'
    end
  end
end