from datetime import datetime
from django.test import TestCase
from django.shortcuts import resolve_url as r
from myproject.core.models import Person
from .data import PERSON_DICT


class PersonModelTest(TestCase):

    def setUp(self):
        self.obj = Person(**PERSON_DICT)
        self.obj.save()

    def test_create(self):
        self.assertTrue(Person.objects.exists())

    def test_created_at(self):
        ''' Person must have an auto created_at attr. '''
        self.assertIsInstance(self.obj.created, datetime)

    def test_str(self):
        self.assertEqual('Regis da Silva', str(self.obj))

    def test_get_absolute_url(self):
        url = r('core:person_detail', self.obj.pk)
        self.assertEqual(url, self.obj.get_absolute_url())
