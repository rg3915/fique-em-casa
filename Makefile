shell_person:
	python manage.py shell_plus < shell/shell_person.py

selenium_person:
	python selenium/selenium_person.py

createuser:
	python manage.py createsuperuser --username='admin' --email=''

backup:
	python manage.py dumpdata core --format=json --indent=2 > fixtures.json

load:
	python manage.py loaddata fixtures.json
