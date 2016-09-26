FROM ubuntu:16.04

# Android SDK variables

ENV ANDROID_SDK_URL https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz
ENV ANDROID_SDK_PATH /android
ENV ANDROID_SDK_FILTER platform-tool,android-23,build-tools-24.0.2

# Keystore variables

ENV KEYSTORE_PATH /keys
ENV KEYSTORE_FILE_NAME keystore
ENV KEYSTORE_STOREPASS passwd
ENV KEYSTORE_KEYPASS passwd
ENV KEYSTORE_ALIAS defaultkey
ENV KEYSTORE_DNAME CN=Meteor Android Build, OU=CTIC, O=CTIC, L=Gijon, ST=Asturias, C=ES
ENV KEYSTORE_KEYALG RSA
ENV KEYSTORE_KEYSIZE 2048
ENV KEYSTORE_VALIDITY 10000

# App variables

ENV APP_PATH /app
ENV APP_BUILD_PATH /build

# Install package dependencies

RUN apt-get update && apt-get install -y openjdk-8-jdk wget curl build-essential chrpath \
    libssl-dev libxft-dev libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev

# Download and extract the Android SDK

RUN mkdir -p $ANDROID_SDK_PATH

WORKDIR $ANDROID_SDK_PATH

RUN wget $ANDROID_SDK_URL -O android-sdk.tar.gz
RUN tar xvfz android-sdk.tar.gz
RUN rm -fr android-sdk.tar.gz

# Install the Android SDK

WORKDIR $ANDROID_SDK_PATH/android-sdk-linux

RUN echo "y" | tools/android update sdk --no-ui --filter $ANDROID_SDK_FILTER

# Update Android SDK environment variables

ENV ANDROID_HOME $ANDROID_SDK_PATH/android-sdk-linux
ENV PATH $PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Install Meteor

RUN curl https://install.meteor.com/ | sh

# Install Node

RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g npm

# Create default keystore (user should provide her own)

ENV KEYSTORE_FILE_PATH $KEYSTORE_PATH/$KEYSTORE_FILE_NAME

RUN mkdir -p $KEYSTORE_PATH

RUN keytool -genkey -noprompt -alias $KEYSTORE_ALIAS -dname "$KEYSTORE_DNAME" \
    -keystore $KEYSTORE_FILE_PATH -storepass $KEYSTORE_STOREPASS -keypass $KEYSTORE_KEYPASS \
    -keyalg $KEYSTORE_KEYALG -keysize $KEYSTORE_KEYSIZE -validity $KEYSTORE_VALIDITY

# Initialize the build folder

RUN mkdir -p $APP_BUILD_PATH

VOLUME $APP_BUILD_PATH

# Set build script as default executable

WORKDIR /usr/local/sbin

COPY ./build-android.sh ./
RUN chmod +x ./build-android.sh

CMD ["build-android.sh"]
