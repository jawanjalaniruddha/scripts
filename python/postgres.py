#!/usr/bin/python

import psycopg2

try:
	conn = psycopg2.connect(database="testdb", user="postgresuser", password="test123", host="localhost", port="5432")
	print "Database connected successfully..."
except:
	print "Unable to connect to database"

cur = conn.cursor()
cur.execute('''select * from company''')

rows = cur.fetchall()

print "\nShow me the databases:\n"
for row in rows:
    print "   ", row[0]

