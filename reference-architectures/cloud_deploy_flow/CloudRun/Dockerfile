FROM golang:latest as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY .  ./

RUN go build -mod=readonly -v -o /random-date
RUN chmod +x /random-date

CMD ["/random-date"]