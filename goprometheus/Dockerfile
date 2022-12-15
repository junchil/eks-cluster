FROM golang:1.16-alpine as builder

ENV GO111MODULE=on

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN apk --no-cache add git alpine-sdk build-base gcc

# Build the Go app
RUN go build -o  goprometheus main.go

EXPOSE 8081
CMD ["./goprometheus"]