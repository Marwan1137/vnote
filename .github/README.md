# GitHub Actions CI/CD Setup Guide

This directory contains GitHub Actions workflows for automated testing, building, and releasing the VOYA Flutter application.

## Workflows Overview

### 1. CI Workflow (`.github/workflows/ci.yml`)

Runs on every push and pull request to main branches. Performs:
- Code analysis and formatting checks
- Unit and widget tests with coverage
- Build verification for Android and iOS
- Multi-version Flutter testing

**No setup required** - Works immediately after committing the workflow file.

### 2. Release Workflow (`.github/workflows/release.yml`)

Runs when you push a version tag (e.g., `v1.0.0`). Builds and uploads:
- Signed Android APK and AAB
- Signed iOS IPA
- Creates GitHub Release with artifacts

**Requires setup** - See "Setting Up Release Workflow" below.

## Quick Start

### Enable CI Workflow

1. Commit and push the workflow files to your repository
2. Navigate to the **Actions** tab in GitHub
3. The CI workflow will run automatically on every push/PR

### Test the CI Workflow

```bash
# Make a small change and push
git add .
git commit -m "Test CI workflow"
git push
```

Check the Actions tab to see the workflow running.

## Setting Up Release Workflow

The release workflow requires signing certificates and secrets to build production-ready apps.

### Step 1: Generate Android Keystore

If you don't have a keystore yet, generate one:

```bash
keytool -genkey -v -keystore android/app/release.keystore \
  -alias release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

**Important**: 
- Store the keystore file securely (do NOT commit it to git)
- Remember the passwords you set
- Keep a backup of the keystore file

### Step 2: Configure Android Signing in build.gradle.kts

Update `android/app/build.gradle.kts` to use the keystore for release builds:

```kotlin
android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = java.util.Properties()
                keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
                
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### Step 3: Add GitHub Secrets

Navigate to your repository: **Settings > Secrets and variables > Actions**

#### Android Secrets

Add these secrets for Android signing:

1. **ANDROID_KEYSTORE_BASE64**
   - Encode your keystore file to base64:
     ```bash
     base64 -i android/app/release.keystore | pbcopy  # macOS
     base64 android/app/release.keystore | clip      # Windows
     base64 android/app/release.keystore              # Linux
     ```
   - Paste the entire base64 string as the secret value

2. **ANDROID_KEYSTORE_PASSWORD**
   - The password you used when creating the keystore

3. **ANDROID_KEY_ALIAS**
   - The alias you used (e.g., `release`)

4. **ANDROID_KEY_PASSWORD**
   - The key password (may be same as keystore password)

#### iOS Secrets (Optional)

For iOS releases, you'll need:

1. **IOS_CERTIFICATE_BASE64**
   - Export your `.p12` certificate from Keychain Access
   - Encode to base64:
     ```bash
     base64 -i certificate.p12 | pbcopy
     ```

2. **IOS_CERTIFICATE_PASSWORD**
   - Password for the `.p12` certificate

3. **IOS_PROVISIONING_PROFILE_BASE64**
   - Download provisioning profile from Apple Developer
   - Encode to base64:
     ```bash
     base64 -i profile.mobileprovision | pbcopy
     ```

4. **IOS_APP_STORE_CONNECT_API_KEY** (Optional)
   - JSON key file from App Store Connect
   - Used for automated App Store uploads

### Step 4: Create Export Options for iOS (Optional)

Create `ios/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

Replace `YOUR_TEAM_ID` with your Apple Developer Team ID.

## Creating a Release

### Method 1: Using Git Tags

1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.0+1
   ```

2. Commit and push:
   ```bash
   git add pubspec.yaml
   git commit -m "Bump version to 1.0.0"
   git push
   ```

3. Create and push a tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

4. The release workflow will automatically:
   - Build Android APK and AAB
   - Build iOS IPA
   - Create a GitHub Release
   - Upload all artifacts

### Method 2: Using GitHub UI

1. Go to **Releases > Draft a new release**
2. Choose a tag (create new if needed): `v1.0.0`
3. Add release notes
4. Click **Publish release**
5. The workflow will build and attach artifacts

## Workflow Features

### CI Workflow Features

- **Parallel Execution**: All jobs run in parallel for faster feedback
- **Caching**: Flutter SDK and dependencies are cached
- **Multi-Version Testing**: Tests on Flutter stable and beta versions
- **Coverage Reports**: Test coverage uploaded as artifacts
- **Build Verification**: Ensures app compiles on both platforms

### Release Workflow Features

- **Automatic Version Extraction**: Reads version from git tag
- **Signed Builds**: Creates production-ready signed artifacts
- **Artifact Upload**: Uploads APK, AAB, and IPA to GitHub Releases
- **Release Notes**: Automatically generates release notes

## Troubleshooting

### CI Workflow Fails

**Issue**: Tests failing
- **Solution**: Run tests locally first: `flutter test`
- Check test output in Actions tab

**Issue**: Format check failing
- **Solution**: Run `dart format .` locally and commit changes

**Issue**: Analyze check failing
- **Solution**: Run `flutter analyze` locally and fix issues

**Issue**: Build failing
- **Solution**: Try building locally: `flutter build apk --debug`
- Check for missing dependencies or configuration

### Release Workflow Fails

**Issue**: Android build fails with signing error
- **Solution**: 
  - Verify all Android secrets are set correctly
  - Check that keystore file is valid
  - Ensure `key.properties` format is correct

**Issue**: iOS build fails
- **Solution**:
  - Verify CocoaPods are installed: `cd ios && pod install`
  - Check Xcode project configuration
  - Ensure provisioning profile matches bundle ID

**Issue**: Artifacts not uploaded
- **Solution**:
  - Check that builds completed successfully
  - Verify file paths in workflow
  - Check GitHub Actions permissions

### Common Issues

**Issue**: "Secrets not found"
- **Solution**: Ensure secrets are added in repository settings, not organization settings

**Issue**: "Permission denied"
- **Solution**: Check repository Actions permissions in Settings

**Issue**: "Flutter version not found"
- **Solution**: Update Flutter version in workflow if using a newer version

## Best Practices

1. **Test Locally First**: Always test builds locally before pushing
2. **Incremental Tags**: Use semantic versioning (v1.0.0, v1.1.0, etc.)
3. **Secure Secrets**: Never commit keystores or certificates to git
4. **Review Workflows**: Check Actions tab regularly for failures
5. **Update Dependencies**: Keep Flutter and dependencies up to date
6. **Monitor Coverage**: Track test coverage trends over time

## Workflow Status Badge

Add this to your README.md to show workflow status:

```markdown
![CI](https://github.com/YOUR_USERNAME/YOUR_REPO/workflows/CI/badge.svg)
```

Replace `YOUR_USERNAME` and `YOUR_REPO` with your GitHub username and repository name.

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/cd)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [iOS Code Signing](https://developer.apple.com/support/code-signing/)

## Support

If you encounter issues:
1. Check the Actions tab for detailed error logs
2. Review this documentation
3. Test builds locally to isolate issues
4. Check Flutter and dependency versions

---

**Note**: The CI workflow runs without any secrets. Only the release workflow requires secrets for signing production builds.
