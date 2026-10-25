# Multi-Client White-Label Architecture & Workflow Guide

> **NOTICE FOR AI AGENTS & DEVELOPERS:**
> This codebase serves as the **Core Template Repository (`upstream`)** for a multi-client store and bookkeeping management system.
> When making changes, read this document to understand how code is shared or isolated between the core template and individual client deployments.

---

## 1. Repository Topology

```
                  ┌─────────────────────────────────────────┐
                  │          CORE TEMPLATE REPOSITORY        │
                  │   github.com/yaseeradam/mlintex.git     │
                  │    (Upstream Source of Truth)           │
                  └────────────────────┬────────────────────┘
                                       │
                  ┌────────────────────┴────────────────────┐
                  │                                         │
       git cherry-pick / merge                   git cherry-pick / merge
       (Selective Code Sharing)                  (Selective Code Sharing)
                  │                                         │
                  ▼                                         ▼
   ┌──────────────────────────────┐          ┌──────────────────────────────┐
   │    CLIENT A REPOSITORY       │          │    CLIENT B REPOSITORY       │
   │  github.com/.../client-a     │          │  github.com/.../client-b     │
   ├──────────────────────────────┤          ├──────────────────────────────┤
   │ • Own Firebase Database      │          │ • Own Firebase Database      │
   │ • Client A Branding & Logo   │          │ • Client B Branding & Logo   │
   │ • Client A Bundle / Package  │          │ • Client B Bundle / Package  │
   │ • Custom Features (Optional) │          │ • Custom Features (Optional) │
   └──────────────────────────────┘          └──────────────────────────────┘
```

- **Core Repository (`upstream`)**: Contains shared architectural features, core data models, UI components, offline synchronization engine, and universal bugfixes.
- **Client Repositories (`origin`)**: Clones of the core template with client-specific branding, package names, and independent Firebase databases.

---

## 2. Core Rules for Future AI Agents & Developers

1. **Bugfixes & Universal Features go to Core First**:
   Always implement core enhancements (e.g. sync engine fixes, performance optimizations, generic accounting reports) in this core repository (`mlintex`) first.
2. **Selectively Share Changes via `git cherry-pick`**:
   Never blindly merge everything if a client's requirements differ. Use `git cherry-pick` to selectively port specific commits to individual client repos.
3. **Keep Client Secrets & Data Isolated**:
   **NEVER** commit client-specific Firebase credentials (`google-services.json`, `firebase_options.dart`), client database keys, or client-specific logos into this core template repository.
4. **Client-Specific Customizations Stay in Client Repos**:
   If Client B asks for a custom workflow (e.g. customized tax calculations or proprietary invoice layouts) that Client A shouldn't have, commit that work **only** in Client B's repository.

---

## 3. Step-by-Step: Onboarding a New Client

Follow these steps whenever provisioning a new client from this template:

### Step 3.1: Create GitHub Repo & Clone with Dual Remotes
```powershell
# 1. Clone the core template into a new directory for the client
git clone https://github.com/yaseeradam/mlintex.git client-name-app
cd client-name-app

# 2. Rename original remote to 'upstream' (points to template)
git remote rename origin upstream

# 3. Add the new client's private GitHub repo as 'origin'
git remote add origin https://github.com/yaseeradam/client-name-app.git

# 4. Push the initial code to the client's repository
git push -u origin main
```

### Step 3.2: Configure Client Isolation Checklist

| Component | File Path | What to Change |
| :--- | :--- | :--- |
| **App Title** | `pubspec.yaml`<br>`web/index.html`<br>`web/manifest.json` | Change `M Lin Tex` to client's business name |
| **Android Package ID** | `android/app/build.gradle.kts` | Update `applicationId` & `namespace` (e.g. `com.clientname.shopmanager`) |
| **iOS Bundle Identifier** | `ios/Runner.xcodeproj/project.pbxproj` | Update `PRODUCT_BUNDLE_IDENTIFIER` (e.g. `com.clientname.shopManager`) |
| **Logos & Icons** | `assets/images/logo.png`<br>`web/icons/*`<br>`web/favicon.png` | Replace with client's logo assets |
| **Firebase Project** | `android/app/google-services.json`<br>`lib/firebase_options.dart` | Replace with new client's dedicated Firebase project credentials |

---

## 4. Daily Workflow: Managing & Sharing Changes

### Scenario A: You made a bugfix in `mlintex` and want to share it with Client B

1. In the `mlintex` repository, commit the fix and note the commit hash:
   ```powershell
   git log -1 --oneline
   # Output: a272bba fix: resolve iOS PDF export and cross-device sync
   ```

2. Open the client repository folder (`client-name-app`):
   ```powershell
   # Fetch latest commits from template
   git fetch upstream

   # Apply ONLY the desired fix commit:
   git cherry-pick a272bba

   # Push the update to Client B's repository
   git push origin main
   ```

### Scenario B: You made a feature in `mlintex` you DO NOT want to share with Client B
- **Action**: Do nothing in the client repository. The commit remains exclusively in `mlintex` and will never appear in the client's app.

### Scenario C: Client B paid for a custom feature only for them
- **Action**: Develop and commit directly inside the `client-name-app` repository and push to `origin main`. Never merge or cherry-pick that commit into `upstream` (`mlintex`).

### Scenario D: Pulling all universal updates into a client app
If a client wants all core updates and doesn't have conflicting modifications:
```powershell
git fetch upstream
git merge upstream/main
git push origin main
```
*(If merge conflicts occur in `firebase_options.dart` or `build.gradle.kts`, keep the client's specific configurations).*

---

## 5. Quick Command Reference Cheat Sheet

```powershell
# Check current remotes
git remote -v

# Fetch updates from core template
git fetch upstream

# View last 5 commits from core template
git log upstream/main -n 5 --oneline

# Port a specific commit to this client
git cherry-pick <COMMIT_HASH>

# Abort cherry-pick if conflicts occur
git cherry-pick --abort
```
