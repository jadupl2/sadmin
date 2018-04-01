flush privileges;
CREATE USER 'sadmin'@'localhost' IDENTIFIED BY 'Nimdas17';
CREATE USER 'squery'@'localhost' IDENTIFIED BY 'Squery17';
grant all privileges    on sadmin.* to 'sadmin'@'localhost';
grant select, show view on sadmin.* to 'squery'@'localhost';
flush privileges;
select User, Host, Password  from mysql.user;
