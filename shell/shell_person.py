import string
import random
import csv
from myproject.core.models import Person, Phone

PHONE_TYPE = ('pri', 'com', 'res', 'cel')
person_list = []

''' Read person.csv '''
with open('fix/person.csv', 'r') as f:
    r = csv.DictReader(f)
    for dct in r:
        person_list.append(dct)
    f.close()

''' Insert Persons '''
obj = [Person(**person) for person in person_list]
Person.objects.bulk_create(obj)


def gen_phone():
    digits_ = str(''.join(random.choice(string.digits) for i in range(11)))
    return '{} 9{}-{}'.format(digits_[:2], digits_[3:7], digits_[7:])

''' Insert Phones '''
persons = Person.objects.all()
for person in persons:
    for i in range(1, random.randint(1, 5)):
        Phone.objects.create(
            person=person,
            phone=gen_phone(),
            phone_type=random.choice(PHONE_TYPE))

# Done
