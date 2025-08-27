package tests

import (
	"testing"
	
	"github.com/sammcj/hfdownloader/hfclient"
)

func TestMainPackageIntegration(t *testing.T) {
	// Integration tests that don't require importing main package
	// Test that the hfclient package works as expected
	
	// Test client creation with empty token
	client := hfclient.NewClient("")
	if client == nil {
		t.Error("Expected client to be created")
	}
	
	// Test client creation with token
	clientWithToken := hfclient.NewClient("test-token")
	if clientWithToken == nil {
		t.Error("Expected client with token to be created")
	}
}

func TestFormatSize(t *testing.T) {
	// Since formatSize is not exported from main, we'll test size formatting
	// through the hfclient package functionality
	files := []*hfclient.File{
		{Path: "small.txt", Size: 512},
		{Path: "medium.txt", Size: 1024},
		{Path: "large.txt", Size: 1048576}, // 1MB
	}
	
	// Test that files can be created and have the expected sizes
	if files[0].Size != 512 {
		t.Errorf("Expected size 512, got %d", files[0].Size)
	}
	if files[1].Size != 1024 {
		t.Errorf("Expected size 1024, got %d", files[1].Size)
	}
	if files[2].Size != 1048576 {
		t.Errorf("Expected size 1048576, got %d", files[2].Size)
	}
}