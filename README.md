# palette

A collection of various experiments with Metal on Apple platforms.
Inspired by [sample-metal](https://github.com/dehesa/sample-metal).

Available projects:
- [Shader Exam](https://github.com/leon196/SIGExam)
- [Dissolve Effect](https://uvolchyk.me/blog/crafting-a-dissolve-effect-in-metal)
- [Harmonic Oscillation](https://uvolchyk.me/blog/oscillating-glowing-strings-with-metal-and-swiftui)

## How to run it

1. Install [mise](https://mise.jdx.dev/installing-mise.html) package manager.
```
curl https://mise.run | sh
```

2. Edit `mise.toml` configuration to run local development on device.
```
[env]
TUIST_DEVELOPMENT_TEAM = '<development team id>'
TUIST_BUNDLE_ID_PREFIX = '<project prefix>'

[tools]
tuist = "latest"
```

3. Install [tuist](https://docs.tuist.dev/es/guides/quick-start/install-tuist) build tool.
```
mise install tuist
```

4. Install project dependencies.
```
mise exec -- tuist install
```

5. Generate workspace.
```
mise exec -- tuist generate
```

If need to edit the workspace configuration
```
mise exec -- tuist edit
```
