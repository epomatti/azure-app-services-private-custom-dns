FROM golang:alpine AS builder

WORKDIR /build
COPY . .
RUN go mod download
RUN go build .

FROM golang:alpine

WORKDIR /app
COPY --from=builder /build/main .

ENTRYPOINT ["/app/main"]
