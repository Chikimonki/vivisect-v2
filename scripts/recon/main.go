// ~/vivisect/scripts/recon/main.go
// Automated binary reconnaissance tool
// Run against any ELF and get a structured JSON report

package main

import (
	"debug/elf"
	"encoding/json"
	"fmt"
	"os"
)

type ReconReport struct {
	Path     string        `json:"path"`
	Type     string        `json:"type"`
	Machine  string        `json:"machine"`
	Entry    string        `json:"entry"`
	Sections []SectionInfo `json:"sections"`
	Imports  []string      `json:"imports"`
	Strings  []string      `json:"interesting_strings"`
}

type SectionInfo struct {
	Name   string `json:"name"`
	Type   string `json:"type"`
	Addr   string `json:"addr"`
	Size   uint64 `json:"size"`
	Exec   bool   `json:"executable"`
	Write  bool   `json:"writable"`
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <binary>\n", os.Args[0])
		os.Exit(1)
	}

	path := os.Args[1]
	f, err := elf.Open(path)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()

	report := ReconReport{
		Path:    path,
		Type:    f.Type.String(),
		Machine: f.Machine.String(),
		Entry:   fmt.Sprintf("0x%X", f.Entry),
	}

	for _, s := range f.Sections {
		si := SectionInfo{
			Name:  s.Name,
			Type:  s.Type.String(),
			Addr:  fmt.Sprintf("0x%X", s.Addr),
			Size:  s.Size,
			Exec:  s.Flags&elf.SHF_EXECINSTR != 0,
			Write: s.Flags&elf.SHF_WRITE != 0,
		}
		report.Sections = append(report.Sections, si)
	}

	symbols, err := f.ImportedSymbols()
	if err == nil {
		for _, sym := range symbols {
			report.Imports = append(report.Imports, sym.Name)
		}
	}

	out, _ := json.MarshalIndent(report, "", "  ")
	fmt.Println(string(out))
}
