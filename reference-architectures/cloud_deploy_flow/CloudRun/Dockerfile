FROM golang:1.23 as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY .  ./

RUN go build -mod=readonly -v -o /random-date \
  && chmod +x /random-date

CMD ["/random-date"]
