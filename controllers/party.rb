require './controllers/base'

class PartyController < BaseController
  get '/:id' do
    @party = Party.new
    haml :party
  end
  get '/:id/attend' do |id|
    @attendance = @member.attendances.select { |a| a.party_id == id.to_i }.first
    @Attendance ||= Attendance.new
    haml :attend
  end
  post '/:id/attend' do |id|
    if attendance = Attendance.where(member_id: @member.id, party_id: id)
      attendance.update(vegitarian: params[:vegitarian] == 'true',
                        non_alcoholic: params[:non_alcoholic] == 'true',
                        allergies: params[:allergies])
      flash[:success] = "Din anmälan är ändrad"
      publish 'attendance.update', attendance.to_hash
    else
      attendance = Attendance.create(vegitarian: params[:vegitarian] == 'true',
                                       non_alcoholic: params[:non_alcoholic] == 'true',
                                       allergies: params[:allergies],
                                       member_id: @member.id,
                                       party_id: id)
      flash[:success] = "De är nu anmäld!"
      publish 'attendance.create', attendance.to_hash
    end
    redirect '/'
  end
end
