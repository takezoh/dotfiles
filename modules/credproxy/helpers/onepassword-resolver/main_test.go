package main

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"testing"
)

type fakeSecrets struct {
	values map[string]string
	err    error
}

func (f fakeSecrets) Resolve(_ context.Context, ref string) (string, error) {
	if f.err != nil {
		return "", f.err
	}
	return f.values[ref], nil
}

func protectedHome(t *testing.T) string {
	t.Helper()
	home := t.TempDir()
	root := filepath.Join(home, ".secrets")
	directory := filepath.Join(root, "op")
	if err := os.Mkdir(root, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.Mkdir(directory, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, "service-account.token"), []byte("TEST_SERVICE_ACCOUNT_TOKEN\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	return home
}

func TestResolveUsesFixedRouteReference(t *testing.T) {
	home := protectedHome(t)
	ref := routeHeaders["v1/sync/remote"]["Authorization"].SecretRef
	var observedToken string
	result, err := resolve(context.Background(), request{Route: "v1/sync/remote"}, home,
		func(_ context.Context, token string) (secrets, error) {
			observedToken = token
			return fakeSecrets{values: map[string]string{ref: "TEST_BEARER"}}, nil
		})
	if err != nil {
		t.Fatal(err)
	}
	if observedToken != "TEST_SERVICE_ACCOUNT_TOKEN" {
		t.Fatal("protected token was not passed directly to the SDK factory")
	}
	if result.Headers["Authorization"] != "Bearer TEST_BEARER" || result.ExpiresInSec != expiresInSec {
		t.Fatalf("unexpected response: %#v", result)
	}
}

func TestResolveRejectsInvalidTokenMode(t *testing.T) {
	home := protectedHome(t)
	path := filepath.Join(home, ".secrets", "op", "service-account.token")
	if err := os.Chmod(path, 0o644); err != nil {
		t.Fatal(err)
	}
	_, err := resolve(context.Background(), request{Route: "v1/sync/remote"}, home,
		func(context.Context, string) (secrets, error) { return fakeSecrets{}, nil })
	if err == nil || err.Error() != "credential_source_unavailable" {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestResolveSanitizesSDKFailure(t *testing.T) {
	home := protectedHome(t)
	_, err := resolve(context.Background(), request{Route: "v1/sync/remote"}, home,
		func(context.Context, string) (secrets, error) {
			return nil, errors.New("TEST_SERVICE_ACCOUNT_TOKEN")
		})
	if err == nil || err.Error() != "credential_source_unavailable" {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestResolveRejectsUnknownRouteBeforeReadingAuthority(t *testing.T) {
	_, err := resolve(context.Background(), request{Route: "unknown"}, "/not-used", nil)
	if err == nil || err.Error() != "unknown_route" {
		t.Fatalf("unexpected error: %v", err)
	}
}
