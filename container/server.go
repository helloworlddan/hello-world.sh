package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/helloworlddan/tortune/tortune"
)

func main() {
	http.Handle("/", http.FileServer(http.Dir("./site")))

	for _, endpoint := range []string{"mail", "post"} {
		http.HandleFunc(fmt.Sprintf("/%s", endpoint), func(w http.ResponseWriter, r *http.Request) {
			w.Write(
				[]byte(
					"<head><meta http-equiv=\"refresh\" content=\"0; url=mailto:stamer@google.com\" /></head>",
				),
			)
		})
	}

	for _, endpoint := range []string{"tel", "phone", "call"} {
		http.Handle(
			fmt.Sprintf("/%s", endpoint),
			http.RedirectHandler("tel:+491736548706", http.StatusMovedPermanently),
		)
	}

	for _, endpoint := range []string{"cal", "gcal", "calendar", "schedule"} {
		http.Handle(
			fmt.Sprintf("/%s", endpoint),
			http.RedirectHandler(
				"https://calendar.app.google/kknKZS8UgJtMDvpq7",
				http.StatusSeeOther,
			),
		)
	}

	for _, endpoint := range []string{"git", "github", "code"} {
		http.Handle(
			fmt.Sprintf("/%s", endpoint),
			http.RedirectHandler("https://github.com/helloworlddan", http.StatusSeeOther),
		)
	}

	for _, endpoint := range []string{"joke", "laugh", "fun", "tortune"} {
		http.HandleFunc(fmt.Sprintf("/%s", endpoint), func(w http.ResponseWriter, r *http.Request) {
			w.Write([]byte(tortune.HitMe()))
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	err := http.ListenAndServe(fmt.Sprintf(":%s", port), nil)
	if err != nil {
		log.Fatal(err)
	}
}
