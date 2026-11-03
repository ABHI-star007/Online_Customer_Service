#!/bin/sh
set -e

# Only start the bundled MariaDB when no external database is configured.
if [ -z "$DB_URL" ]; then
  mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld
  if [ ! -d /var/lib/mysql/mysql ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db > /dev/null
  fi
  mariadbd --user=mysql --datadir=/var/lib/mysql &

  i=0
  until mariadb-admin ping --silent 2>/dev/null; do
    i=$((i + 1))
    [ "$i" -gt 60 ] && echo "MariaDB did not start" && exit 1
    sleep 1
  done

  DB_USERNAME=${DB_USERNAME:-csc}
  DB_PASSWORD=${DB_PASSWORD:-csc}
  mariadb -u root <<SQL
CREATE DATABASE IF NOT EXISTS CSC;
CREATE USER IF NOT EXISTS '${DB_USERNAME}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER IF NOT EXISTS '${DB_USERNAME}'@'127.0.0.1' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL ON CSC.* TO '${DB_USERNAME}'@'localhost';
GRANT ALL ON CSC.* TO '${DB_USERNAME}'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
  export DB_URL="jdbc:mysql://127.0.0.1:3306/CSC"
  export DB_USERNAME DB_PASSWORD
  # Hibernate 6.2 cannot auto-detect the dialect for MariaDB 11.x
  export SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.MariaDBDialect
fi

exec java -jar /app/app.jar
