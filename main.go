package main

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/helloworlddan/run"
	"github.com/helloworlddan/tortune/tortune"
)

type Link struct {
	RedirectURL string `firestore:"redirect_to"`
}

func main() {
	for _, endpoint := range []string{"contact", "card"} {
		http.HandleFunc(
			fmt.Sprintf("GET /%s", endpoint),
			func(w http.ResponseWriter, r *http.Request) {
				vcardLines := []string{
					"BEGIN:VCARD",
					"VERSION:3.0",
					"N:Stamer;Daniel;;;",
					"FN:Daniel Stamer",
					"PRONOUNS;LANGUAGE=en;PREF=1:he/her",
					"PHOTO;PNG:https://hello-world.sh/static/avatar.png",
					"KEY;PGP:https://hello-world.sh/key/hello-world",
					"ORG:Google;Forward Deployed Engineering",
					"TITLE:Staff Software Engineer",
					"TEL;TYPE=CELL,VOICE:+491736548706",
					"EMAIL;TYPE=WORK:stamer@google.com",
					"EMAIL;TYPE=HOME:dan@hello-world.sh",
					"URL:https://hello-world.sh",
					"ADR;TYPE=WORK:;;ABC-Str. 19;Hamburg;Hamburg;20354;Germany",
					"END:VCARD",
					"",
				}
				vcardData := strings.Join(vcardLines, "\r\n")

				w.Header().Set("Content-Type", "text/vcard; charset=utf-8")
				w.Header().Set("Content-Disposition", `attachment; filename="daniel_stamer.vcf"`)
				w.Header().Set("Content-Length", fmt.Sprintf("%d", len(vcardData)))

				w.Write([]byte(vcardData))
			},
		)
	}

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
