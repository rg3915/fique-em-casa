from django.test import TestCase
from django.shortcuts import resolve_url as r
from myproject.core.models import Person
from .data import PERSON_DICT


class TalkListGet(TestCase):

    def setUp(self):
        self.obj = Person.objects.create(**PERSON_DICT)
        self.resp = self.client.get(r('core:person_list'))

    def test_get(self):
        self.assertEqual(200, self.resp.status_code)

    def test_template(self):
        self.assertTemplateUsed(self.resp, 'core/person_list.html')

    def test_html(self):
        contents = [
            (1, 'Regis da Silva'),
            (1, 'regis@example.com'),
            (1, 'São Paulo'),
        ]

        for count, expected in contents:
            with self.subTest():
                self.assertContains(self.resp, expected, count)


class PersonGetEmpty(TestCase):

    def test_get_empty(self):
        response = self.client.get(r('core:person_list'))

        self.assertContains(response, 'Sem itens na lista.')
