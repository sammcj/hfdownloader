package tests

import (
	"testing"

	"github.com/sammcj/hfdownloader/hfclient"
)

func TestHfclientIntegration(t *testing.T) {
	// Integration tests for hfclient package
	
	// Test client creation
	client := hfclient.NewClient("test-token")
	if client == nil {
		t.Fatal("Expected client to be created, got nil")
	}
	
	// Test file structure
	file := &hfclient.File{
		Path: "test.txt",
		Size: 1024,
		Sha:  "test-sha",
	}
	
	if file.GetSha() != "test-sha" {
		t.Errorf("Expected SHA test-sha, got %s", file.GetSha())
	}
	
	// Test LFS file
	lfsFile := &hfclient.File{
		Path:  "large.bin",
		IsLFS: true,
		Lfs: &hfclient.LfsInfo{
			Oid:  "lfs-sha",
			Size: 2048,
		},
	}
	
	if lfsFile.GetSha() != "lfs-sha" {
		t.Errorf("Expected LFS SHA lfs-sha, got %s", lfsFile.GetSha())
	}
	
	// Test RepoRef
	repo := &hfclient.RepoRef{
		Owner: "test-owner",
		Name:  "test-repo",
		Ref:   "main",
	}
	
	expected := "test-owner/test-repo"
	if repo.FullName() != expected {
		t.Errorf("Expected full name %s, got %s", expected, repo.FullName())
	}
}

func TestFilterFiles(t *testing.T) {
	files := []*hfclient.File{
		{Path: "model.safetensors", Size: 1024},
		{Path: "config.json", Size: 512},
		{Path: "tokenizer.json", Size: 256},
	}

	// Test filtering with glob pattern
	filtered := hfclient.FilterFiles(files, []string{"*.json"})
	if len(filtered) != 2 {
		t.Errorf("Expected 2 filtered files, got %d", len(filtered))
	}
}

func TestPrintFileTree(t *testing.T) {
	files := []*hfclient.File{
		{Path: "test.txt", Size: 100},
		{Path: "dir/nested.txt", Size: 200},
	}
	
	// This should not panic
	defer func() {
		if r := recover(); r != nil {
			t.Errorf("PrintFileTree panicked: %v", r)
		}
	}()
	
	hfclient.PrintFileTree(files)
}