AVNSP
=========
This is a distributed web application. Where the different parts are connected via AMQP (RabbitMQ).
Specific actions should emit events which other applications then can react on.

For example the image upload works like this:
The web app has a page where users can select which files to upload.
When the server has received the images the web apps responsibilites stops. It send the files on to a queue.
On the other end a photo processing app handles compression, scaling and uploading the images to a persistent storage.

Requirements
------------
* Ruby-2.3
* RabbitMQ 3.5
* Postgresql 9.2 +

###Setup env
```
createdb avnsp
rabbitmqctl add_vhost avnsp
rabbitmqctl set_permission -p avnsp .* .* .*
```
###Migrate db locally
```
sequel -m migrations/ postgres://localhost/avnsp
```
###Start
```
bundle install
bundle exec puma
```
