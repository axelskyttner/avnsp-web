require 'json'
require 'mail'

Mail.defaults do
  delivery_method :smtp, { 
    :address              => "email-smtp.us-east-1.amazonaws.com",
    :port                 => 587,
    :domain               => "academian.se",
    :user_name            => ENV.fetch('SES_ACCESS_KEY'),
    :password             => ENV.fetch('SES_SECRET_KEY'),
    :authentication       => 'plain',
    :enable_starttls_auto => true
  }
end

class EmailWorker
  def start
    subscribe("member.login", "member.login") do |_, msg|
      s = Struct.new(:email, :token, :ts, :hostname)
      extras = s.new(msg[:email], msg[:token], msg[:ts], msg[:hostname])
      send msg[:email], "[Academian] login-länk", haml(:login, extras)
    end

    subscribe('party.invitation', 'send-invitations') do |_, msg|
      s = Struct.new(:nick, :party_date, :party_name, :party_last_att_date,
                     :party_id, :balance, :balance_after, :street, :zip, :city)
      extras = s.new(msg[:nick], msg[:party_date], msg[:party_name],
                     msg[:party_last_att_date], msg[:party_id], msg[:balance],
                     msg[:balance_after], msg[:street], msg[:zip], msg[:city])
      send(msg[:email],
           "[Academian] Inbjudan #{msg[:party_name]}",
           haml(:invitation, extras))
    end
  end

  private
  def send to, sub, body
    if ENV['RACK_ENV'] == 'development'
      puts body
      return
    end
    Mail.deliver do
      from          'auth@academian.se'
      to            to
      subject       sub
      content_type  'text/html; charset=UTF-8'
      body          body
    end 
  end

  def haml(file_name, extras)
    file = File.read("./emails/#{file_name}.haml")
    engine = Haml::Engine.new(file)
    engine.render(extras)
  end
end
