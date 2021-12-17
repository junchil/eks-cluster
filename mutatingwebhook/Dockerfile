#
# Build go project
#
FROM golang:1.17-alpine as go-builder

WORKDIR /go/src/github.com/junchil/eks-cluster/mutatingwebhook

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o mutatingwebhook *.go

#
# Runtime container
#
FROM alpine:latest  

RUN mkdir -p /app && \
    addgroup -S app && adduser -S app -G app && \
    chown app:app /app

WORKDIR /app

COPY --from=go-builder /go/src/github.com/junchil/eks-cluster/mutatingwebhook .

USER app

CMD ["./mutatingwebhook"]  