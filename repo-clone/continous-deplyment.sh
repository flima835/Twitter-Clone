# Define uma tag baseada na data/hora para ser sempre única
TAG=$(date +%s)

# Faz o build com a tag dinâmica
gcloud builds submit --tag us-central1-docker.pkg.dev/twitter-clone-sre/repo-clone/app:$TAG .

# Faz o deploy usando a mesma tag
kubectl set image deployment/twitter-app twitter-container=us-central1-docker.pkg.dev/twitter-clone-sre/repo-clone/app:$TAG