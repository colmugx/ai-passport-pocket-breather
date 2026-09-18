# Pocket Breather

Pocket Breather is a tiny offline breathing coach built from scratch for AI Passport. It uses only the public `colmugx/ai-passport@0.0.6` application API: no template code, assets, Host ABI, or local SDK checkout.

## Controls

- **UP**: next breathing pattern
- **DOWN**: previous breathing pattern
- **OK**: start/pause

Patterns:

- **BOX** — 4 / 4 / 4 / 4 seconds
- **CALM** — 4 / 1 / 6 / 1 seconds
- **FOCUS** — 5 / 2 / 5 / 2 seconds

The orb grows while inhaling, stays large during the first hold, shrinks while exhaling, and stays small during the second hold. The app also shows the Host-provided battery percentage.

## Build

```sh
moon update
moon check --target native
moon test --target native
moonx colmugx/ai-passport/cmd/passport@0.0.6 build --host web
moonx colmugx/ai-passport/cmd/passport@0.0.6 build --host folotoy-ai-passport
```

> Built with ChatGPT.

> And Built by ChatGPT.