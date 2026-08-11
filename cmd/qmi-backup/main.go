// qmi-backup creates an SQLite-consistent snapshot using VACUUM INTO.
package main

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	_ "modernc.org/sqlite"
)

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintln(os.Stderr, "usage: qmi-backup /path/to/qmi-web.db /path/to/snapshot.db")
		os.Exit(2)
	}
	source, target := os.Args[1], os.Args[2]
	if filepath.Clean(source) == filepath.Clean(target) {
		fmt.Fprintln(os.Stderr, "qmi-backup: source and target must differ")
		os.Exit(2)
	}
	if err := os.MkdirAll(filepath.Dir(target), 0o700); err != nil {
		fmt.Fprintf(os.Stderr, "qmi-backup: create target directory: %v\n", err)
		os.Exit(1)
	}
	if err := os.Remove(target); err != nil && !os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "qmi-backup: remove prior snapshot: %v\n", err)
		os.Exit(1)
	}
	db, err := sql.Open("sqlite", "file:"+source)
	if err != nil {
		fmt.Fprintf(os.Stderr, "qmi-backup: open: %v\n", err)
		os.Exit(1)
	}
	defer db.Close()
	if _, err := db.Exec("PRAGMA busy_timeout = 5000"); err != nil {
		fmt.Fprintf(os.Stderr, "qmi-backup: set busy timeout: %v\n", err)
		os.Exit(1)
	}
	escaped := strings.ReplaceAll(target, "'", "''")
	if _, err := db.Exec("VACUUM INTO '" + escaped + "'"); err != nil {
		fmt.Fprintf(os.Stderr, "qmi-backup: consistent snapshot: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("qmi-backup: snapshot created")
}
