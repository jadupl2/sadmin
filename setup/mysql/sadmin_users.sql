flush privileges;
CREATE USER 'sadmin'@'localhost' IDENTIFIED BY 'Nimdas17';
grant all privileges on sadmin.* to 'sadmin'@'localhost';
CREATE USER 'squery'@'localhost' IDENTIFIED BY 'Squery18';
grant select, show view on sadmin.* to 'squery'@'localhost';
grant all privileges on *.* to 'root'@'localhost' identified by 'helene';
flush privileges;
