from django.test import TestCase
from django.shortcuts import resolve_url as r
from myproject.core.models import Person
from .data import PERSON_DICT


class PersonDetailGet(TestCase):

    def setUp(self):
        self.obj = Person.objects.create(**PERSON_DICT)
        self.resp = self.client.get(r('core:person_detail', self.obj.pk))

    def test_get(self):
        self.assertEqual(200, self.resp.status_code)

    def test_template(self):
        self.assertTemplateUsed(
            self.resp, 'core/person_detail.html')

    def test_context(self):
        person = self.resp.context['person']
        self.assertIsInstance(person, Person)

    def test_html(self):
        contents = (self.obj.first_name,
                    self.obj.last_name,
                    self.obj.email,
                    self.obj.address,
                    self.obj.complement,
                    self.obj.district,
                    self.obj.city,
                    self.obj.uf,
                    self.obj.cep)

        with self.subTest():
            for expected in contents:
                self.assertContains(self.resp, expected)


class PersonDetailNotFound(TestCase):

    def test_not_found(self):
        resp = self.client.get(r('core:person_detail', 0))
        self.assertEqual(404, resp.status_code)
