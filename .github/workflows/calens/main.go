package main

import (
	"bufio"
	"errors"
	"fmt"
	"io/ioutil"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"

	"text/template"

	"github.com/Masterminds/sprig/v3"
	"github.com/spf13/pflag"
)

var opts struct {
	Output       string
	InputDir     string
	TemplateFile string
	Versions     []string
}

func init() {
	pflag.StringVarP(&opts.InputDir, "input", "i", "changelog", "read input files from `dir`")
	pflag.StringVarP(&opts.Output, "output", "o", "", "write generated changelog to this `file` (default: print to stdout)")
	pflag.StringVarP(&opts.TemplateFile, "template", "t", filepath.FromSlash("changelog/CHANGELOG.tmpl"), "read template from `file`")
	pflag.StringSliceVar(&opts.Versions, "version", nil, "only print `version` (separate multiple versions with commas)")
	pflag.Parse()
}

func die(msg string, args ...interface{}) {
	if !strings.HasSuffix(msg, "\\n") {
		msg += "\n"
	}
	fmt.Fprintf(os.Stderr, msg, args...)
	os.Exit(1)
}

// files lists all file names in dir. The file name is split by _, and the first component is used as the key in the resulting map.
func files(dir string) []string {
	d, err := os.Open(dir)
	if err != nil {
		die("error opening dir: %v", err)
	}

	names, err := d.Readdirnames(-1)
	if err != nil {
		_ = d.Close()
		die("error listing dir: %v", err)
	}

	err = d.Close()
	if err != nil {
		die("error closing dir: %v", err)
	}

	sort.Strings(names)

	var files []string
	for _, name := range names {
		// skip the template and versions file
		if name == "TEMPLATE" || name == "releases" {
			continue
		}

		// skip dot files
		if strings.HasPrefix(name, ".") {
			continue
		}

		files = append(files, filepath.Join(dir, name))
	}

	return files
}

// Release is one release, with an optional release date.
type Release struct {
	path    string
	Version string
	Date    *time.Time
}

// ReleaseSlice allows sorting a slice of releases by the release date
// with Go < 1.8
type ReleaseSlice []Release

// Len is the number of elements in the collection.
func (s ReleaseSlice) Len() int {
	return len(s)
}

// Less reports whether the element with
// index i should sort before the element with index j.
func (s ReleaseSlice) Less(i, j int) bool {
	if s[i].Date == nil {
		return true
	}

	if s[j].Date == nil {
		return false
	}

	return s[j].Date.Before(*s[i].Date)
}

// Swap swaps the elements with indexes i and j.
func (s ReleaseSlice) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}

var versionRegex = regexp.MustCompile(`^(\d+\.\d+\.\d+)(_(\d{4}-\d{2}-\d{2}))?$`)

// readReleases lists the directory and parses all releases from the subdir
// names there. A valid release subdir has the format "x.y.z_YYYY-MM-DD", the
// underscore and date is optional (for unreleased versions). The resulting
// slice is sorted by the release dates, starting with unreleased versions and
// continuing with the other versions, newest first.
func readReleases(dir string) (result []Release) {
	f, err := os.Open(dir)
	if err != nil {
		die("unable to open dir: %v", err)
	}

	entries, err := f.Readdir(-1)
	if err != nil {
		die("unable to list directory: %v", err)
	}

	err = f.Close()
	if err != nil {
		die("close dir: %v", err)
	}

	for _, entry := range entries {
		if !entry.Mode().IsDir() {
			continue
		}

		if entry.Name() == "unreleased" {
			rel := Release{
				path:    filepath.Join(dir, entry.Name()),
				Version: "unreleased",
			}
			result = append(result, rel)
			continue
		}

		data := versionRegex.FindStringSubmatch(entry.Name())
		if len(data) == 0 {
			die("invalid subdir name %v", filepath.Join(dir, entry.Name()))
			continue
		}

		ver := data[1]
		date := data[3]

		rel := Release{
			path:    filepath.Join(dir, entry.Name()),
			Version: ver,
		}

		if date != "" {
			t, err := time.Parse("2006-01-02", date)
			if err != nil {
				die("unable to parse date %q: %v", date, err)
			}
			rel.Date = &t
		}

		result = append(result, rel)
	}

	sort.Sort(ReleaseSlice(result))

	return result
}

// Entry describes a change.
type Entry struct {
	Type       string
	TypeShort  string
	Title      string
	Paragraphs []string
	URLs       []*url.URL
	Issues     []string
	IssueURLs  []*url.URL
	PRs        []string
	PRURLs     []*url.URL
	OtherURLs  []*url.URL
	PrimaryID  string
	PrimaryURL *url.URL
}

// EntryTypePriority contains the list of valid types, order is priority in the changelog.
var EntryTypePriority = map[string]int{
	"Security":    1,
	"Bugfix":      2,
	"Change":      3,
	"Enhancement": 4,
}

// EntryTypeAbbreviation contains the shortened entry types for the overview.
var EntryTypeAbbreviation = map[string]string{
	"Security":    "Sec",
	"Bugfix":      "Fix",
	"Change":      "Chg",
	"Enhancement": "Enh",
}

// EntrySlice allows sorting a slice of releases by the priority of the entry
// (as defined in EntryTypePriority) with Go < 1.8
type EntrySlice []Entry

// Len is the number of elements in the collection.
func (s EntrySlice) Len() int {
	return len(s)
}

// Less reports whether the element with
// index i should sort before the element with index j.
func (s EntrySlice) Less(i, j int) bool {
	return EntryTypePriority[s[i].Type] < EntryTypePriority[s[j].Type]
}

// Swap swaps the elements with indexes i and j.
func (s EntrySlice) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}

// Punctuation contains all the characters that are not allowed as the last character in the title.
const Punctuation = ".!?"

// Valid returns an error if the entry is invalid in any way.
func (e Entry) Valid() error {
	if e.Type == "" {
		return errors.New("entry title does not have a prefix, example: Bugfix: restore old behavior")
	}

	if e.Title == "" {
		return errors.New("entry does not have a title")
	}

	if e.PrimaryID == "" {
		return errors.New("primary issue ID not found")
	}

	lastChar := e.Title[len(e.Title)-1]
	if strings.ContainsAny(string(lastChar), Punctuation) {
		return fmt.Errorf("title ends with punctuation, e.g. a character out of %q", Punctuation)
	}

	if _, ok := EntryTypePriority[e.Type]; !ok {
		return fmt.Errorf("entry type %q is invalid, valid types: %v", e.Type, EntryTypePriority)
	}

	if len(e.Type)+len(e.Title)+1 > 80 {
		return errors.New("title is too long")
	}

	return nil
}

func readFile(filename string) (e Entry) {
	f, err := os.Open(filename)
	if err != nil {
		die("unable to open %v: %v", filename, err)
	}

	sc := bufio.NewScanner(f)
	if !sc.Scan() {
		die("unable to read first line from %v", filename)
	}

	title := sc.Text()
	data := strings.SplitN(title, ": ", 2)
	if len(data) == 2 {
		e.Type = strings.TrimSpace(capitalize(data[0]))
		e.TypeShort = EntryTypeAbbreviation[e.Type]
		data = data[1:]
	}
	e.Title = strings.TrimSpace(capitalize(data[0]))

	var text []string
	var sect string
	for sc.Scan() {
		if sc.Err() != nil {
			die("unable to read lines from %v: %v", filename, sc.Err())
		}

		if strings.TrimSpace(sc.Text()) == "" {
			if sect != "" {
				text = append(text, sect)
			}

			sect = ""
			continue
		}

		if sect != "" {
			sect += " "
		}
		sect += strings.TrimSpace(sc.Text())
	}

	err = f.Close()
	if err != nil {
		die("error closing %v: %v", filename, err)
	}

	if sect != "" {
		text = append(text, sect)
	}

	if len(text) > 0 {
		links := text[len(text)-1]
		text = text[:len(text)-1]

		sc = bufio.NewScanner(strings.NewReader(links))
		sc.Split(bufio.ScanWords)
		for sc.Scan() {
			url, err := url.Parse(sc.Text())
			if err != nil {
				die("file %v: unable to parse url %q: %v", filename, sc.Text(), err)
			}
			e.URLs = append(e.URLs, url)
		}
	}

	for _, par := range text {
		e.Paragraphs = append(e.Paragraphs, capitalize(strings.TrimSpace(par)))
	}

	githubIDs(e.URLs, &e)

	err = e.Valid()
	if err != nil {
		die("file %v: %v", filename, err)
	}

	return e
}

var (
	issueRegexp       = regexp.MustCompile(`/.*/.*/issues/(\d+)`)
	pullRequestRegexp = regexp.MustCompile(`/.*/.*/pull/(\d+)`)
)

// githubIDs extracts all issue and pull request IDs from the urls.
func githubIDs(urls []*url.URL, e *Entry) {
	for _, url := range urls {
		if url.Host != "github.com" {
			e.OtherURLs = append(e.OtherURLs, url)
			continue
		}

		switch {
		case issueRegexp.MatchString(url.Path):
			data := issueRegexp.FindStringSubmatch(url.Path)
			id := data[1]
			e.Issues = append(e.Issues, id)
			e.IssueURLs = append(e.IssueURLs, url)

			if e.PrimaryID == "" {
				e.PrimaryID = id
				e.PrimaryURL = url
			}
		case pullRequestRegexp.MatchString(url.Path):
			data := pullRequestRegexp.FindStringSubmatch(url.Path)
			id := data[1]
			e.PRs = append(e.PRs, id)
			e.PRURLs = append(e.PRURLs, url)

			if e.PrimaryID == "" {
				e.PrimaryID = id
				e.PrimaryURL = url
			}
		default:
			e.OtherURLs = append(e.OtherURLs, url)
		}
	}
}

func readEntries(dir string, versions []Release) (entries map[string][]Entry) {
	entries = make(map[string][]Entry)

	for _, ver := range versions {
		for _, file := range files(ver.path) {
			entries[ver.Version] = append(entries[ver.Version], readFile(file))
		}
	}

	// sort all entries according to priority, otherwise leave the original ordering
	for ver, list := range entries {
		sort.Stable(EntrySlice(list))
		entries[ver] = list
	}

	return entries
}

// wrapIndent formats the text in a column smaller than width characters,
// indenting each new line with indent spaces.
func wrapIndent(text string, width, indent int) (result string, err error) {
	sc := bufio.NewScanner(strings.NewReader(text))
	sc.Split(bufio.ScanWords)
	cl := 0
	for sc.Scan() {
		if sc.Err() != nil {
			return "", sc.Err()
		}

		if cl+len(sc.Text()) > width {
			result += "\n"
			result += strings.Repeat(" ", indent)
			cl = 0
		}

		if cl > 0 {
			result += " "
		}
		result += sc.Text()
		cl += len(sc.Text())
	}

	return result, nil
}

// capitalize returns a string with the first letter in upper case.
func capitalize(text string) string {
	if text == "" {
		return text
	}

	first, rest := text[0:1], text[1:]
	return strings.ToUpper(first) + rest
}

var helperFuncs = template.FuncMap{
	"wrapIndent": wrapIndent,
	"capitalize": capitalize,
}

func main() {
	buf, err := ioutil.ReadFile(opts.TemplateFile)
	if err != nil {
		die("unable to read template from %v: %v", opts.TemplateFile, err)
	}

	funcMap := sprig.GenericFuncMap()

	for i, m := range helperFuncs {
		funcMap[i] = m
	}

	templ, err := template.New("").Funcs(funcMap).Parse(string(buf))

	if err != nil {
		die("unable to compile template: %v", err)
	}

	type VersionChanges struct {
		Version string
		Date    string
		Entries []Entry
	}

	allReleases := readReleases(opts.InputDir)

	var changes []VersionChanges
	var releases []Release

	if len(opts.Versions) == 0 {
		releases = allReleases
	} else {
		for _, rel := range allReleases {
			for _, ver := range opts.Versions {
				if ver == rel.Version {
					releases = append(releases, rel)
				}
			}
		}
	}

	all := readEntries(opts.InputDir, releases)
	for _, ver := range releases {
		if len(all[ver.Version]) == 0 {
			continue
		}

		vc := VersionChanges{
			Version: ver.Version,
			Entries: all[ver.Version],
		}

		if ver.Date != nil {
			vc.Date = ver.Date.Format("2006-01-02")
		} else {
			vc.Date = "UNRELEASED"
		}

		changes = append(changes, vc)
	}

	wr := os.Stdout

	if opts.Output != "" {
		wr, err = os.Create(opts.Output)
		if err != nil {
			die("unable to create file %v: %v", opts.Output, err)
		}
	}

	err = templ.Execute(wr, changes)
	if err != nil {
		die("error executing template: %v", err)
	}

	if opts.Output != "" {
		err = wr.Close()
		if err != nil {
			die("error closing file %v: %v", opts.Output, err)
		}
	}
}
