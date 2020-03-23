package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"cloud.google.com/go/profiler"
	"contrib.go.opencensus.io/exporter/stackdriver"
	"go.opencensus.io/trace"
)

func main() {
	err := profiler.Start(profiler.Config{
		Service:              "hwsh-blog",
		NoHeapProfiling:      true,
		NoAllocProfiling:     true,
		NoGoroutineProfiling: true,
		DebugLogging:         true,
		ServiceVersion:       "1.0.0",
	})
	if err != nil {
		log.Fatal(err)
	}
	exporter, err := stackdriver.NewExporter(stackdriver.Options{})
	if err != nil {
		log.Fatal(err)
	}
	trace.RegisterExporter(exporter)
	exporter.StartMetricsExporter()
	defer exporter.StopMetricsExporter()
	trace.ApplyConfig(trace.Config{DefaultSampler: trace.AlwaysSample()})
	_, span := trace.StartSpan(context.Background(), "main")
	defer span.End()

	fs := http.FileServer(http.Dir("./site"))
	http.Handle("/", fs)

	port := os.Getenv("PORT")

	log.Println(fmt.Sprintf("Listening on :%s...", port))
	err = http.ListenAndServe(fmt.Sprintf(":%s", port), nil)
	if err != nil {
		log.Fatal(err)
	}
}
