# Use an official Node.js runtime as a parent image
FROM node:18

# Set the working directory to /usr/src/app
WORKDIR /usr/src/app

# Install nvm and set up Node.js version
ENV NVM_DIR /root/.nvm
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install 18.17.0 && \
    nvm use 18.17.0 && \
    nvm alias default 18.17.0 && \
    npm install -g npm@latest

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
