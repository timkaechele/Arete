module Arete
  class Application < Sinatra::Base
    set :root, File.expand_path('../../', __FILE__)
    set :public_folder, File.join(settings.root, 'assets')
    set :views, File.join(settings.root, 'views')

    get '/' do
      erb :landing_page
    end

    get '/calendar.ics' do
      content_type 'text/text;charset=utf8'

      gitlab_fetcher = GitlabFetcher.new(protocol: params['protocol'],
                        base_url: params['url'],
                        access_token: params['token'])

      calendar = GitlabCalendarBuilder.new(gitlab_fetcher).build

      calendar.to_ical
    end
  end
end
