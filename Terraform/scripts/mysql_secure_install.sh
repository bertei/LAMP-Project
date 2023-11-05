#!/usr/bin/expect

set password "asd123"

spawn sudo mysql_secure_installation

expect "Enter current password for root (enter for none):"
send "\r"
expect "Switch to unix_socket authentication"
send "n\r"
expect "Change the root password?"
send "y\r"
expect "New password:"
send "$password\r"
expect "Re-enter new password:"
send "$password\r"
expect "Remove anonymous users?"
send "y\r"
expect "Disallow root login remotely?"
send "n\r"
expect "Remove test database and access to it?"
send "n\r"
expect "Reload privilege tables now?"
send "y\r"

# interact