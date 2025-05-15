FROM golang:1.24-alpine AS builder

WORKDIR /build
COPY . .
RUN go mod download
RUN go build .

FROM golang:1.24-alpine

WORKDIR /app
COPY --from=builder /build/main .

ENTRYPOINT ["/app/main"]
