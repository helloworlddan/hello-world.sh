package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {

	fs := http.FileServer(http.Dir("./site"))
	http.Handle("/", fs)

	port := os.Getenv("PORT")

	log.Println(fmt.Sprintf("Listening on :%s...", port))
	err := http.ListenAndServe(fmt.Sprintf(":%s", port), nil)
	if err != nil {
		log.Fatal(err)
	}
}
