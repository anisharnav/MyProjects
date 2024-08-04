#!/bin/bash
#
<< task
Deploy a Django app
task

code_clone() {
	echo "Cloning the Django app.."
	git clone https://github.com/LondheShubham153/django-notes-app.git
}

install_requirements() {
	echo "Installing dependencies"
	sudo apt-get install docker.io nginx docker-compose -y	
}

required_restarts() {
	sudo chown $USER /var/run/docker.sock
	#sudo systemctl enable docker
	#sudo systemctl enable nginx
	#sudo systemctl restart docker
}

deploy () {
	docker build -t notes-app .
	#docker run -d -p 8000:8000 notes-app:latest
	docker-compose run -d

}

echo "******************* DEPLOYMENT STARTED ********************"

if ! code_clone;
then
	echo "the app directory already exists"
	cd django-notes-app
fi


if ! install_requirements;
then
	echo "Installation Failed"
	exit 1
fi


if ! required_restarts;
then
	echo "System Fault Detected"
	exit 1
fi

if ! deploy;
then
	echo "Deployment failed"
	exit  1
fi

echo "******************* DEPLOYMENT DONE ********************"
