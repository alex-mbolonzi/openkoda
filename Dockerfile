# First stage: Build the JAR file
FROM maven:3.9.9-eclipse-temurin-17 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven project files
COPY openkoda/pom.xml ./openkoda/
COPY openkoda/src/ ./openkoda/src
COPY openkoda-app/pom.xml ./openkoda-app/
COPY pom.xml ./
COPY .git ./.git

# Build the JAR file
RUN mvn -f openkoda/pom.xml clean install spring-boot:repackage -DskipTests

# Second stage: Create the final image
FROM eclipse-temurin:17-jdk

# Set the JAR file location
ARG JAR_FILE=/app/openkoda/build/openkoda-1.7.1.jar

# Set up user and group
ARG UID=20000
ARG GID=20000
RUN groupadd -r -g $GID openkoda-cloud && useradd -m -u $UID -g $GID -s /bin/bash openkoda-cloud

# Set the working directory inside the container
WORKDIR /app
RUN mkdir /data /var/log/openkoda /config

# Copy the JAR file from the build stage
COPY --from=build ${JAR_FILE}  application.jar

# Copy the entry script
COPY docker/entrypoint.sh .

# Make the entry script executable
RUN chmod +x entrypoint.sh
RUN chown -R openkoda-cloud:openkoda-cloud /app /data /config /var/log/openkoda
RUN chmod ugo+rwX /data /var/log/openkoda /config

# Set environment variables
ENV SPRING_DATASOURCE_URL=jdbc:postgresql://dpg-cr9eb4l6l47c73clkp90-a.oregon-postgres.render.com/openkoda
ENV SPRING_DATASOURCE_USERNAME=openkoda_user
ENV SPRING_DATASOURCE_PASSWORD=IXLwRknxxYd6Dk0N8j86r83WCYEjDj47
ENV BASE_URL=http://localhost:8080/
ENV APPLICATION_ADMIN_EMAIL=almbolonzi@gmail.com
ENV INIT_ADMIN_USERNAME=admin
ENV INIT_ADMIN_PASSWORD=admin123
ENV INIT_ADMIN_FIRSTNAME=Alex
ENV INIT_ADMIN_LASTNAME=Mbolonzi
ENV INIT_EXTERNAL_SCRIPT=
ENV FILE_STORAGE_FILESYSTEM_PATH=/data
ENV SPRING_PROFILES_ACTIVE=openkoda,development
ENV STORAGE_TYPE=db
ENV SPRING_CONFIG_LOCATION=classpath:/,/config/

USER openkoda-cloud

# Set the entry script as the default command to run when the container starts
ENTRYPOINT ["./entrypoint.sh"]
