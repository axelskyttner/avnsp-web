require './controllers/base'
require "base64"

class PhotoController < BaseController
  get '/' do
    @parties = Party.order(:date)
    haml :photo
  end

  get '/:uuid/:name' do |uuid, name|
    s3 = AWS::S3.new
    objects = s3.buckets['avnsp'].objects
    img = objects["avnsp/#{uuid}/#{name}"]
    content_type img.content_type
    img.read
  end

  post '/' do
    params[:files].each_with_index do |f, i|
      tempfile = f[:tempfile]
      size = tempfile.size
      file = tempfile.read
      caption = params[:captions][i]
      photo = Photo.create(name: f[:filename],
                           s3_path: "avnsp/photos",
                           caption: caption,
                           member_id: session[:id],
                           event_id: params[:event_id])
      publish 'photo.upload', photo.to_hash.merge(file: Base64.encode64(file),
                                                  size: size,
                                                  content_type: f[:type])
    end
    flash[:info] = "Bilderna kommer snart synas."
    redirect back
  end
end
