#!/bin/bash
# Fail on any error
set -e

echo "=== 1. Installing OpenJDK 17 ==="
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk-headless unzip wget

# Create SDK directory in user's home
export ANDROID_HOME=$HOME/android-sdk
mkdir -p $ANDROID_HOME/cmdline-tools

echo "=== 2. Downloading Android Command Line Tools ==="
cd /tmp
wget -q --show-progress https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip

echo "=== 3. Extracting Command Line Tools ==="
unzip -q cmdline-tools.zip
# The zip extracts into 'cmdline-tools'. We move it to the 'latest' structure required by sdkmanager
mv cmdline-tools latest
mv latest $ANDROID_HOME/cmdline-tools/

# Clean up zip
rm cmdline-tools.zip

# Set up paths for the script session
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

echo "=== 4. Accepting Android Licenses ==="
# Accept licenses automatically
yes | sdkmanager --licenses

echo "=== 5. Installing SDK Platform & Build Tools ==="
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

echo "=== 6. Configuring Flutter Android Path ==="
flutter config --android-sdk $ANDROID_HOME

echo "=== 7. Appending variables to bash profile ==="
# Add env variables permanently to user's bash profile
if ! grep -q "ANDROID_HOME" ~/.bashrc; then
  echo 'export ANDROID_HOME=$HOME/android-sdk' >> ~/.bashrc
  echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools' >> ~/.bashrc
fi

echo "==============================================="
echo "✅ Android SDK setup completed successfully!"
echo "Please run: source ~/.bashrc"
echo "Then build your app: flutter build apk --release"
echo "==============================================="
