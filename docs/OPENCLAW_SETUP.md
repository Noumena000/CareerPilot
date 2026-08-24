# OpenClaw setup

CareerPilot uses OpenClaw's OpenAI-compatible HTTP surface for its first native integration. This is a local-owner integration, not a multi-user cloud boundary.

## Enable the endpoint

In the OpenClaw Gateway configuration, enable Chat Completions:

```json5
{
  gateway: {
    mode: "local",
    http: {
      endpoints: {
        chatCompletions: {
          enabled: true
        }
      }
    },
    auth: {
      mode: "token"
    }
  }
}
```

Start or restart the Gateway, then verify that its model list is available on loopback:

```text
GET http://127.0.0.1:18789/v1/models
Authorization: Bearer YOUR_GATEWAY_TOKEN
```

CareerPilot expects at least one agent target such as `openclaw/default`.

## Configure CareerPilot

1. Open CareerPilot Settings.
2. Keep the default loopback URL unless the local Gateway uses a different port.
3. Enter the Gateway token.
4. Choose **Save and verify**.

The app stores the token in macOS Keychain. It stores only the non-secret Gateway URL in preferences.

## Security warning

A shared Gateway token is an owner/operator credential. CareerPilot rejects non-loopback hosts in the initial implementation. Do not expose this endpoint or token to the public internet, place it in the Safari extension, commit it to this repository, or paste it into application pages.

## Verification limits

A green CI build proves compilation and endpoint-policy tests. It does not prove that a Gateway is installed, configured, authenticated, or reachable on the user's Mac. The Settings screen reports success only after `/v1/models` returns a real OpenClaw agent target.
