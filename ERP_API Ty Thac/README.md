# Build Image

docker build -t erpapi .

# Run Container

docker run -itd --name erpapi -p 80:80 -p 443:443 erpapi
