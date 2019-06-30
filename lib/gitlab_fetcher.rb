class GitlabFetcher
  PER_PAGE = 50

  attr_accessor(:protocol,
                :base_url,
                :access_token,
                :faraday_connection)

  class FetchFailureError < StandardError
    attr_reader(:resource,
                :response)
    def initialize(resource:, response: nil)
      super
      @resource = resource
      @response = response
    end
  end


  def initialize(protocol:,  base_url:, access_token:)
    @protocol = protocol
    @base_url = base_url
    @access_token = access_token

    @faraday_connection = Faraday.new(protocol + '://' + base_url) do |builder|
      builder.use Faraday::Response::Logger
        builder.headers['Private-Token'] = access_token
        builder.headers['User-Agent'] = 'Arete'
        builder.response :oj
        builder.adapter :typhoeus
    end
  end

  def issues
    # Get statistics to allow fetching of issues in parallel
    statistics_response = faraday_connection.get('/api/v4/issues_statistics', {
      scope: 'assigned_to_me'
    })

    if statistics_response.status != 200
      raise FetchFailureError.new(resource: :issues_statistics, response: statistics_response)
    end

    statistics_body = statistics_response.body

    opened_count = statistics_body['statistics']['counts']['opened']
    page_count = (opened_count / PER_PAGE.to_f).ceil

    issue_responses = []
    faraday_connection.in_parallel do
      (1..page_count).each do |i|
        issue_responses.push faraday_connection.get('/api/v4/issues', {
          per_page: PER_PAGE,
          page: i,
          scope: 'assigned_to_me',
          state: 'opened'
        })
      end
    end

    # Only issues with 200 status code and a due date are interesting
    issue_responses.select { |response| response.status == 200 }
                   .flat_map { |response| response.body }
                   .select { |issue| !issue['due_date'].nil? }
                   .map do |issue|
                     {
                      name: issue['title'],
                      due_date: issue['due_date'],
                      project_id: issue['project_id'],
                      url: issue['web_url'],
                     }
                   end
  end

  def milestones(projects)
    milestone_respones = []
    faraday_connection.in_parallel do
      projects.each do |project|
        milestone_respones.push(faraday_connection.get("api/v4/projects/#{project[:id]}/milestones", {
          per_page: 100,
          state: 'active'
        }))
      end
    end
    milestone_respones.select { |response| response.status == 200 }
                      .flat_map { |response| response.body }
                      .select { |milestone| !milestone['due_date'].nil? }
                      .map do |milestone|
                        {
                          name: milestone['title'],
                          project_id: milestone['project_id'],
                          url: milestone['web_url'],
                          due_date: milestone['due_date']
                        }
                      end
  end

  def projects
    stats_request = faraday_connection.head('/api/v4/projects', {
      per_page: PER_PAGE
    })
    return [] if stats_request.status != 200
    total_pages = stats_request.headers['X-Total-Pages'].to_i

    project_requests = []
    faraday_connection.in_parallel do
      (1..total_pages).each do |i|
        project_requests.push(faraday_connection.get('/api/v4/projects', {
          page: i,
          per_page: PER_PAGE
        }))
      end
    end

    project_requests.select { |response| response.status == 200 }
                   .flat_map { |response| response.body }
                   .map do |project|
                      {
                        id: project['id'],
                        name: project['name'],
                        group: project['group'],
                        url: project['web_url'],
                        full_identifier: project['path_with_namespace']
                      }
                   end
  end
end
