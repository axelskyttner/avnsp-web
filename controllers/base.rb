require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/reloader'
require 'haml'
require './amqp'

class BaseController < Sinatra::Base
  register Sinatra::Flash
  set :views, "./views"
  set :haml, escape_html: true

  configure :development do
    enable :logging
  end
  before do
    @member = Member[session[:id]]
  end

  register Sinatra::Reloader if development?

  helpers do
    def subscribe qname, *topics, &blk
      TH.subscribe(qname, *topics, &blk)
    end
    def publish routing_key, data
      TH.publish routing_key, data
    end
    def next_parties
      today = Date.today
      parties = Party.
        where(date: (today..today.next_year)).
        order(:date)
    end
  end
end
