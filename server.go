package main

import (
	"context"
	"fmt"
	"net/http"

	"cloud.google.com/go/firestore"
	"github.com/helloworlddan/run"
	"github.com/helloworlddan/tortune/tortune"
)

type Link struct {
	RedirectURL string `firestore:"redirect_to"`
}

func main() {
	ctx := context.Background()

	// Lazy load FireStore client
	var fsClient *firestore.Client
	run.LazyClient("firestore", func() {
		var err error
		fsClient, err = firestore.NewClient(ctx, run.ProjectID())
		if err != nil {
			run.Error(nil, err)
		}
		run.Client("firestore", fsClient)
	})

	http.HandleFunc("GET /s/{token}", func(w http.ResponseWriter, r *http.Request) {
		token := r.PathValue("token")
		if token == "" {
			run.Warning(r, "no token supplied")
			http.Error(w, "no token supplied", http.StatusBadRequest)
			return
		}

		var fsClient *firestore.Client
		fsClient, err := run.UseClient("firestore", fsClient)
		if err != nil {
			run.Warningf(r, "can't connect to database: %v", err)
			http.Error(w, "can't connect to database", http.StatusInternalServerError)
			return
		}
		docSnap, err := fsClient.Collection("links").Doc(token).Get(ctx)
		if err != nil {
			run.Warning(r, "token not found")
			http.Error(w, "token not found", http.StatusNotFound)
			return
		}

		var link Link
		err = docSnap.DataTo(&link)
		if err != nil {
			run.Warning(r, "bad data entry")
			http.Error(w, "bad data entry", http.StatusInternalServerError)
			return
		}

		http.Redirect(w, r, link.RedirectURL, http.StatusMovedPermanently)
	})

	for _, endpoint := range []string{"mail", "post"} {
		http.HandleFunc(
			fmt.Sprintf("GET /%s", endpoint),
			func(w http.ResponseWriter, r *http.Request) {
				w.Write(
					[]byte(
						"<head><meta http-equiv=\"refresh\" content=\"0; url=mailto:stamer@google.com\" /></head>",
					),
				)
			},
		)
	}

	for _, endpoint := range []string{"tel", "phone", "call"} {
		http.Handle(
			fmt.Sprintf("GET /%s", endpoint),
			http.RedirectHandler("tel:+491736548706", http.StatusMovedPermanently),
		)
	}

	for _, endpoint := range []string{"cal", "gcal", "calendar", "schedule"} {
		http.Handle(
			fmt.Sprintf("GET /%s", endpoint),
			http.RedirectHandler(
				"https://calendar.app.google/kknKZS8UgJtMDvpq7",
				http.StatusSeeOther,
			),
		)
	}

	for _, endpoint := range []string{"git", "github", "code"} {
		http.Handle(
			fmt.Sprintf("GET /%s", endpoint),
			http.RedirectHandler("https://github.com/helloworlddan", http.StatusSeeOther),
		)
	}

	for _, endpoint := range []string{"joke", "laugh", "fun", "tortune"} {
		http.HandleFunc(
			fmt.Sprintf("GET /%s", endpoint),
			func(w http.ResponseWriter, r *http.Request) {
				w.Write([]byte(tortune.HitMe()))
			},
		)
	}

	http.Handle("/", http.FileServer(http.Dir("./site")))

	err := run.ServeHTTP(nil, nil)
	if err != nil {
		run.Fatal(nil, err)
	}
}
