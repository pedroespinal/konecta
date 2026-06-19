FROM golang:1.22-alpine AS builder
RUN apk add --no-cache ca-certificates git
WORKDIR /app
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o relay .

FROM alpine:3.19
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/relay .
EXPOSE 8080
CMD ["./relay"]
