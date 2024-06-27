# Use an official Node.js runtime as a parent image
FROM node:18

# Install Java
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk && \
    apt-get clean;

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
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
