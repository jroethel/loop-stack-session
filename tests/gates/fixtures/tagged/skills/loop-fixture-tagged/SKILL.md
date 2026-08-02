# loop-fixture-tagged

Before any Step - this "Offer the commit" line must NOT flag (before first `## Step`).

## Not a step section

This "offer the commit" line must NOT flag (section heading is not `## Step`).

```
In a fence - this "Want me to commit" line must NOT flag (code block).
```

## Step 1 - Ask things`[gate:ASK]`

Want me to commit it now?
Wait for the response.

## Step 2 - Untagged step, clean

No gate-signal tokens here, so no tag is required and nothing flags.
