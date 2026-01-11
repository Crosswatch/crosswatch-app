# GitHub Pages Setup Instructions

This guide explains how to enable GitHub Pages for automatic PWA deployment.

## Prerequisites

- Repository hosted on GitHub
- Push access to the repository
- Admin or write permissions to configure GitHub Pages

## Setup Steps

### 1. Enable GitHub Pages

1. Go to your repository on GitHub
2. Click on **Settings** (top navigation)
3. In the left sidebar, click **Pages** (under "Code and automation")
4. Under "Build and deployment":
   - **Source**: Select "GitHub Actions"
   - (Do NOT select "Deploy from a branch" - we're using Actions instead)

### 2. Configure Repository Permissions

The workflow needs permissions to deploy to GitHub Pages:

1. In repository **Settings** → **Actions** → **General**
2. Scroll to **Workflow permissions**
3. Select: **Read and write permissions**
4. Check: **Allow GitHub Actions to create and approve pull requests**
5. Click **Save**

### 3. Update Base Path (if needed)

The workflow is configured for a repository named `crosswatch-app`:

```yaml
flutter build web --release --base-href /crosswatch-app/
```

**If your repository has a different name**, edit `.github/workflows/deploy-web.yml` line 32:

```yaml
# Change this:
--base-href /crosswatch-app/

# To match your repo name:
--base-href /YOUR-REPO-NAME/
```

**For organization/user pages** (e.g., `username.github.io`):
```yaml
--base-href /
```

### 4. Push Changes

Once you push the workflow file to the `main` branch, GitHub Actions will:

1. Detect the push
2. Run the build job (install Flutter, build web)
3. Run the deploy job (publish to GitHub Pages)
4. Your app will be live at: `https://YOUR-USERNAME.github.io/YOUR-REPO-NAME/`

## Monitoring Deployment

1. Go to **Actions** tab in your repository
2. Click on the latest "Deploy to GitHub Pages" workflow run
3. Watch the build and deploy jobs in real-time
4. Once complete, visit your GitHub Pages URL

## Manual Deployment

If you need to manually trigger a deployment:

1. Go to **Actions** tab
2. Click "Deploy to GitHub Pages" workflow (left sidebar)
3. Click **Run workflow** button
4. Select `main` branch
5. Click **Run workflow**

## Troubleshooting

### Build Fails

- Check the Actions logs for Flutter build errors
- Ensure `flutter pub get` succeeds
- Verify all dependencies are in `pubspec.yaml`

### 404 Error After Deployment

**Problem**: App loads but shows blank page or 404 errors

**Solution**: Check the base-href path:
- Repository pages need: `--base-href /repo-name/`
- User/org pages need: `--base-href /`

### Workflow Permissions Error

**Problem**: `Resource not accessible by integration`

**Solution**: Enable workflow permissions (see step 2 above)

### Page Not Found

**Problem**: GitHub Pages is not enabled

**Solution**: 
1. Settings → Pages
2. Source: "GitHub Actions" (not "Deploy from a branch")

## PWA Installation

Once deployed, users can install the PWA:

**Desktop (Chrome/Edge):**
- Look for install icon in address bar (⊕ or ⬇)
- Click to install as desktop app

**Mobile (Chrome/Safari):**
- Open site in browser
- Tap "Share" → "Add to Home Screen"
- Opens like a native app

## Custom Domain (Optional)

To use a custom domain:

1. Add `CNAME` file to `web/` directory with your domain
2. In GitHub Settings → Pages → Custom domain, enter your domain
3. Configure DNS with your provider:
   ```
   CNAME record: www.yourdomain.com → YOUR-USERNAME.github.io
   ```

## Workflow Configuration

The workflow (`.github/workflows/deploy-web.yml`) consists of two jobs:

**Build Job:**
- Sets up Flutter 3.24.0 stable
- Installs dependencies
- Builds web bundle
- Uploads artifact for deployment

**Deploy Job:**
- Takes build artifact
- Deploys to GitHub Pages environment
- Returns public URL

## Costs

GitHub Pages is **free** for public repositories with:
- 100GB storage
- 100GB bandwidth/month
- Unlimited builds with GitHub Actions (2000 minutes/month for private repos)

---

## Quick Reference

**Repository URL**: `https://github.com/YOUR-USERNAME/crosswatch-app`
**GitHub Pages URL**: `https://YOUR-USERNAME.github.io/crosswatch-app/`
**Workflow File**: `.github/workflows/deploy-web.yml`
**Build Output**: `build/web/`

**Build Command**:
```bash
flutter build web --release --base-href /crosswatch-app/
```

**Local Testing**:
```bash
flutter build web --release
python3 -m http.server --directory build/web 8000
# Visit: http://localhost:8000
```
