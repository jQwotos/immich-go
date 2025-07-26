# Stage 1: The Builder
# We use the official golang image which has Go and git pre-installed.
# Using a specific version ensures the build is reproducible.
FROM golang:1.24.5-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

COPY . .

# Build the Go application.
# -o /immich-go specifies the output path for the compiled binary.
# CGO_ENABLED=0 creates a statically linked binary, which is ideal for minimal base images.
RUN CGO_ENABLED=0 go build -o /immich-go


# Stage 2: The Final Image
# We use a minimal alpine image to keep the final image size small.
FROM alpine:latest

# Install ca-certificates for making HTTPS requests to the Immich server
# and tzdata for timezone support, which immich-go may need.
RUN apk add --no-cache ca-certificates tzdata

# Create a non-root user to run the application for better security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy the compiled binary from the 'builder' stage into our final image.
# We place it in /usr/local/bin so it's in the system's PATH.
COPY --from=builder /immich-go /usr/local/bin/immich-go

# Create a directory for the uploads. This is where you will mount your takeout files.
# Also, set the correct ownership for this directory.
RUN mkdir /uploads && chown appuser:appgroup /uploads

# Switch to the non-root user
USER appuser

# Set the working directory to the uploads folder.
# This means commands will be run from this directory by default.
WORKDIR /uploads

# Set the entrypoint for the container. When the container starts, it will
# execute 'immich-go'. You will provide the sub-commands and arguments
# (like 'upload from-google-photos ...') when you run the container.
ENTRYPOINT ["immich-go"]