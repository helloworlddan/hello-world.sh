FROM golang:1.22-bullseye as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY server.go ./
RUN CGO_ENABLED=0 go build -v -o server

FROM gcr.io/distroless/static
WORKDIR /app
COPY --from=builder /app/server /app/server
ADD ./site /app/site/
CMD ["/app/server"] 
