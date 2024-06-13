CREATE DATABASE IF NOT EXISTS cristian;
USE cristian;
CREATE USER 'cristian'@'%' IDENTIFIED BY 'cristian';
GRANT ALL PRIVILEGES ON cristian.* TO 'cristian'@'%';
FLUSH PRIVILEGES;
