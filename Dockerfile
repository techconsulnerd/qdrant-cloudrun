# Use the official Qdrant image as a parent image
FROM qdrant/qdrant:latest

# Set the Qdrant API key
ARG QDRANT_API_KEY
ENV QDRANT__SERVICE__API_KEY=$QDRANT_API_KEY

# Expose the gRPC and REST API ports
EXPOSE 6333 6334

# Copy the custom configuration file
COPY ./config/production.yaml /qdrant/config/production.yaml

# The command to run Qdrant
CMD ["./qdrant", "--config-path", "config/production.yaml"]