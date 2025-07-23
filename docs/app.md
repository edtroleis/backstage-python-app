# Build Python App

## Run Python App Locally

### Project Structure with Virtual Environment
```
project/
├── venv/                 # Virtual environment (don't commit)
├── src/                  # Source code
├── tests/                # Test files
├── requirements.txt      # Dependencies
├── .gitignore            # Include venv/
└── README.md
```

### Activate virtual environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/macOS

# Deactivate virtual environment
deactivate

# Remove virtual environment
rm -rf venv
```

### Install dependencies and run the application

```bash
cd src

pip install -r requirements.txt

python3 app.py
```

### Test the application on browser

```bash
http://localhost:5000/api/v1/info
```

## Run Python App in Docker

``` bash
# build image
IMAGE_NAME="python-app"
IMAGE_VERSION="1.0.0"
docker image build -t $DOCKER_HUB_USERNAME/$IMAGE_NAME:$IMAGE_VERSION .

# Run the container
docker run -d --name python-app -p 8080:5000 $IMAGE_NAME:$IMAGEVERSION

# Push to Docker Hub
docker login -u $DOCKER_HUB_USERNAME -p $DOCKER_HUB_TOKEN

docker tag <image_name>:<version> $DOCKER_HUB_USERNAME/$IMAGE_NAME:$IMAGE_VERSION

docker push $DOCKER_HUB_USERNAME/$IMAGE_NAME:$IMAGE_VERSION
```

# Notes
- [Python app repository](https://github.com/ricardoandre97/python-app)
