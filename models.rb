require 'bcrypt'
require 'securerandom'
require 'sequel'

Sequel::Model.plugin :json_serializer

class Member < Sequel::Model
  one_to_many :attendances

  include BCrypt
  def password
    @password ||= Password.new(self.password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end
  def reset_password
    p = SecureRandom.urlsafe_base64(32 * 3/4)
    self.password = p
    self.save
    p
  end

  def full_name
    [first_name, nick && "\"#{nick}\"", last_name].compact.join " "
  end

  def parties
    attendances.map(&:party)
  end
end

class Party < Sequel::Model
  one_to_many :attendances
  one_to_many :albums

  def description
    "#{name}, #{date}"
  end
end

class Event < Sequel::Model
end

class Photo < Sequel::Model
  many_to_one :member

  def s3_path= path
    self.path = path + "/#{SecureRandom.uuid}.jpg"
    self.thumb_path = self.path.sub('.jpg', '.thumb.jpg')
    self.original_path = self.path.sub('.jpg', '.orig.jpg')
  end
  
  def s3
    s3 = AWS::S3.new
    @objects ||= s3.buckets['avnsp'].objects
  end

  def thumb_temp
    "https://d18qrfc4r3cv12.cloudfront.net/#{self.thumb_path}"
  end

  def file_temp
    "https://d18qrfc4r3cv12.cloudfront.net/#{self.path}"
  end

  def original_temp
    "https://d18qrfc4r3cv12.cloudfront.net/#{self.original_path}"
  end

end

class Attendance < Sequel::Model
  many_to_one :member
  many_to_one :party

  def member_name
    member.full_name
  end

  def member_studied_started
    [member.studied, member.started].join '-'
  end

  def member_previus_attendanceise
    attendances = member.attendances
    type = party.type.include?('lunch') ? 'lunch' : 'fest'
    attendances.select do |a|
      a.party.type.include?(type) && a.party.date < party.date
    end.count
  end
end

class Album < Sequel::Model
  many_to_one :party
  many_to_one :member, key: :created_by
  one_to_many :photos

  def party_name
    party && party.name
  end

  def party_date
    party && party.date
  end

  def title
    [name || party_name, date || party_date || timestamp.to_date].join(' - ')
  end

  def description
    text
  end
end
