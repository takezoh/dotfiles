// onepassword-resolver は credproxy の credential command 契約を実装する。
// 1Password 固有の authority と参照は user-owned integration に閉じ込め、
// provider-neutral な broker へ持ち込まない。
package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"syscall"

	sdk "github.com/1password/onepassword-sdk-go"
)

const (
	expiresInSec      = 3600
	tokenRelativePath = ".secrets/op/service-account.token"
)

var routeHeaders = map[string]map[string]headerSpec{
	"v1/sync/remote": {
		"Authorization": {Prefix: "Bearer ", SecretRef: "op://local-dev/Context Fabric/Service Principal/token"},
	},
	"thirdverse-amsterdam-jenkins": {
		"Authorization": {Prefix: "Bearer ", SecretRef: "op://local-dev/Amsterdam/Jenkins/token"},
	},
}

type request struct {
	Route string `json:"route"`
}

type response struct {
	Headers      map[string]string `json:"headers"`
	ExpiresInSec int               `json:"expires_in_sec"`
}

type headerSpec struct {
	Prefix    string
	SecretRef string
}

type secrets interface {
	Resolve(context.Context, string) (string, error)
}

type secretsFactory func(context.Context, string) (secrets, error)

func sdkFactory(ctx context.Context, token string) (secrets, error) {
	client, err := sdk.NewClient(ctx,
		sdk.WithServiceAccountToken(token),
		sdk.WithIntegrationInfo("credproxy-user-resolver", "v1"),
	)
	if err != nil {
		return nil, err
	}
	return client.Secrets(), nil
}

func resolve(ctx context.Context, req request, home string, factory secretsFactory) (response, error) {
	specs, ok := routeHeaders[req.Route]
	if !ok {
		return response{}, errors.New("unknown_route")
	}
	tokenPath := filepath.Join(home, filepath.FromSlash(tokenRelativePath))
	token, err := readProtectedToken(tokenPath)
	if err != nil {
		return response{}, errors.New("credential_source_unavailable")
	}
	resolver, err := factory(ctx, token)
	token = ""
	if err != nil {
		return response{}, errors.New("credential_source_unavailable")
	}
	headers := make(map[string]string, len(specs))
	for name, spec := range specs {
		value, err := resolver.Resolve(ctx, spec.SecretRef)
		if err != nil {
			return response{}, errors.New("credential_source_unavailable")
		}
		headers[name] = spec.Prefix + value
	}
	return response{Headers: headers, ExpiresInSec: expiresInSec}, nil
}

func readProtectedToken(path string) (string, error) {
	for _, directory := range []string{filepath.Dir(filepath.Dir(path)), filepath.Dir(path)} {
		info, err := os.Lstat(directory)
		if err != nil || !info.IsDir() || info.Mode()&os.ModeSymlink != 0 ||
			info.Mode().Perm() != 0o700 || !ownedByCurrentUser(info) {
			return "", errors.New("protected directory identity invalid")
		}
	}
	info, err := os.Lstat(path)
	if err != nil || !info.Mode().IsRegular() || info.Mode()&os.ModeSymlink != 0 ||
		info.Mode().Perm() != 0o600 || !ownedByCurrentUser(info) {
		return "", errors.New("protected token identity invalid")
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	defer clear(raw)
	token := strings.TrimSpace(string(raw))
	if token == "" {
		return "", errors.New("protected token is empty")
	}
	return token, nil
}

func ownedByCurrentUser(info os.FileInfo) bool {
	stat, ok := info.Sys().(*syscall.Stat_t)
	return ok && stat.Uid == uint32(os.Getuid())
}

func clear(value []byte) {
	for i := range value {
		value[i] = 0
	}
}

func main() {
	if len(os.Args) != 1 {
		fmt.Fprintln(os.Stderr, "reason:bad_request")
		os.Exit(1)
	}
	var req request
	if err := json.NewDecoder(os.Stdin).Decode(&req); err != nil {
		fmt.Fprintln(os.Stderr, "reason:bad_request")
		os.Exit(1)
	}
	home, err := os.UserHomeDir()
	if err != nil || !filepath.IsAbs(home) {
		fmt.Fprintln(os.Stderr, "reason:credential_source_unavailable")
		os.Exit(1)
	}
	result, err := resolve(context.Background(), req, home, sdkFactory)
	if err != nil {
		fmt.Fprintf(os.Stderr, "reason:%s\n", err)
		os.Exit(1)
	}
	if err := json.NewEncoder(os.Stdout).Encode(result); err != nil {
		fmt.Fprintln(os.Stderr, "reason:credential_source_unavailable")
		os.Exit(1)
	}
}
