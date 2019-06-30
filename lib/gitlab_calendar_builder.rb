require 'irb'
class GitlabCalendarBuilder
  attr_reader :gitlab_fetcher
  def initialize(gitlab_fetcher)
    @gitlab_fetcher = gitlab_fetcher
  end

  def build
    calendar = Icalendar::Calendar.new

    projects = gitlab_fetcher.projects
    project_map = Hash[projects.map { |p| [p[:id], p] }]

    issues = gitlab_fetcher.issues
    milestones = gitlab_fetcher.milestones(projects)
    issue_events = build_issue_events(issues, project_map)
    milestone_events = build_milestone_events(milestones, project_map)

    (issue_events + milestone_events).each do |event|
      calendar.add_event(event)
    end

    calendar
  end

  def build_milestone_events(milestones, project_map)
    milestones.map do |milestone|
      due_date = milestone[:due_date].gsub('-', '')

      event = Icalendar::Event.new
      event.dtstart = Icalendar::Values::Date.new(due_date)
      event.dtend = Icalendar::Values::Date.new(due_date)
       event.summary = if project_map[milestone[:project_id]].is_a?(Hash)
        "#{project_map[milestone[:project_id]][:name]} #{milestone[:name]}"
      else
        milestone[:name]
      end
      event.url = Icalendar::Values::Uri.new(milestone[:url])
      event
    end
  end

  def build_issue_events(issues, project_map)
    issues.map do |issue|
      due_date = issue[:due_date].gsub('-', '')

      event = Icalendar::Event.new
      event.dtstart = Icalendar::Values::Date.new(due_date)
      event.dtend = Icalendar::Values::Date.new(due_date)
      event.summary = if project_map[issue[:project_id]].is_a?(Hash)
        "#{project_map[issue[:project_id]][:name]} #{issue[:name]}"
      else
        issue[:name]
      end
      event.url =  Icalendar::Values::Uri.new(issue[:url])
      event
    end
  end
end
