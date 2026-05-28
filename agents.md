# agents.md -- ownCloud iOS App

## Repository Overview

The official ownCloud iOS client, written in Swift. Licensed under GPL-3.0, targeting iOS 16+. Uses the ios-sdk (included as a submodule) for all server communication.

## Architecture & Key Paths

- `ownCloud/` -- Main app target
- `ownCloudAppFramework/` -- Shared framework code
- `ownCloudAppShared/` -- Shared utilities across extensions
- `ownCloud.xcodeproj/` -- Xcode project
- `ownCloud Action Extension/` -- iOS Action Extension
- `ownCloud File Provider/` -- iOS Files integration
- `ownCloud Share Extension/` -- Share Sheet extension
- `ownCloud Intents/` -- Siri/Shortcuts intents
- `ios-sdk/` -- Git submodule: ownCloud iOS SDK
- `fastlane/` -- Fastlane deployment configuration
- `doc/` -- Screenshots and documentation images
- `SETUP.md` -- Build instructions
- `CONTRIBUTING.md` -- Contribution guidelines
- `SUPPORT.md` -- Support resources

## Development Conventions

- Swift codebase targeting iOS 16+
- Xcode as the primary build system
- Fastlane for CI/CD and App Store deployment
- Translations via Transifex

## Build & Test Commands

```bash
# Build instructions are in SETUP.md
# Clone with submodules:
git clone --recursive https://github.com/owncloud/ios-app.git
# Open ownCloud.xcodeproj in Xcode and build
```

## Important Constraints

- Licensed under GPL-3.0 (copyleft). Apache 2.0 migration requires resolving copyleft dependencies.
- The ios-sdk submodule is also GPL-3.0.
- All contributions require a DCO sign-off.
- The LICENSE file in the repository root is the authoritative license source.


## OSPO Policy Constraints

### GitHub Actions
- **Only** use actions owned by `owncloud`, created by GitHub (`actions/*`), verified on the GitHub Marketplace, or verified by the ownCloud Maintainers.
- Pin all actions to their full commit SHA (not tags): `uses: actions/checkout@<SHA> # vX.Y.Z`
- Never introduce actions from unverified third parties.

### Dependency Management
- Dependabot is configured for automated dependency updates.
- Review and merge Dependabot PRs as part of regular maintenance.
- Do not introduce new dependencies without discussion in an issue first.

### Git Workflow
- **Rebase policy**: Always rebase; never create merge commits. Use `git pull --rebase` and `git rebase` before pushing.
- **Signed commits**: All commits **must** be PGP/GPG signed (`git commit -S -s`).
- **DCO sign-off**: Every commit needs a `Signed-off-by` line (`git commit -s`).
- **Conventional Commits & Squash Merge**: Use the [Conventional Commits](https://www.conventionalcommits.org/) format where the repository enforces it. Many repos use squash merge, where the PR title becomes the commit message on the default branch — apply Conventional Commits format to PR titles as well. A reusable GitHub Actions workflow enforces this.

## Context for AI Agents

This is a native iOS app built with Swift and UIKit. The app uses a modular architecture with separate extensions for Files, Share Sheet, and Intents. The ios-sdk submodule handles all server API communication. Any changes should be made using Xcode-compatible project settings.
