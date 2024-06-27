# Use a CentOS-based Node.js runtime as a parent image
FROM centos:8

# Switch to CentOS Stream repositories
RUN dnf -y install centos-release-stream && dnf -y swap centos-{linux,stream}-repos && dnf -y distro-sync

# Install Node.js
RUN dnf module install -y nodejs:14

# Install Java
RUN dnf -y update && \
    dnf -y install java-11-openjdk-devel && \
    dnf clean all

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# Set the working directory to /usr/src/app
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install any needed packages
RUN npm install

# Copy the rest of the application source code to the working directory
COPY . .

# Make port 8080 available to the world outside this container
EXPOSE 8080

# Define environment variable
ENV NODE_ENV production

# Run the app
CMD [ "npm", "start" ]
