# jenkins_with_docker
Run Jenkins on Docker


#   How to use 

## Step 1. This will store the workspace in /var/jenkins_home. , so you can update docker-compose.yaml volumnes setting to customize .

## Step 2.Update plugins.txt to install pre-install plugins  (using core-support plugin format). or Just give pluginID that will get the latest version
    
    pluginID:version
    pluginID
## Step 3. just execute docker-compose up -d 
    
    docker-compose up -d 

Open your browser to [Jenkins]
[Jenkins]: http://localhost:8080       "Jenkins"

# Enjoy it

    