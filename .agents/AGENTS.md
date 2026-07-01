# Project-Scoped Behavioral Rules

* Do not include any AI-attribution messages, references, or footnotes (e.g., "co-authored by Gemini", "written by AI") in git commit messages, source code comments, or documentation. All commits and contributions should be presented as standard developer contributions.
* Always verify/review the correctness of the changes yourself (by running analysis and testing) and then proceed to git commit them directly once they are validated, without requiring a separate user review step.
* Do not prompt the user for a sudo password in the chat or tasks. If an installation or build script requires sudo privileges, provide the command to the user so they can run it themselves.
* Adhere to Conventional Commits specifications (e.g., using prefixes like `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`) and maintain semver Git tags (e.g., `v1.0.0`) for every release, enabling clean changelog generation from tag differences. On every release, it is mandatory to create and update the CHANGELOG.md file.
* Always refer to the `tool/` directory before executing build or release tasks, as scripts for dependency checking (`lib_resolver.sh`), compilation (`package_linux.sh`, `package_android.sh`), and releases (`release.sh`) are already present there.
* Commit and push changes directly to GitHub alongside every change/fix made.
* Be extremely precise and deliberate when making code modifications. Always double-check variable scopes, macro definitions, and bracket matching before proposing changes to avoid careless syntax and compilation errors.
