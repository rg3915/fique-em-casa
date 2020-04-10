from django.test import TestCase
from myproject.core.forms import PersonForm
from .data import PERSON_DICT


class PersonFormTest(TestCase):

    def test_form_has_fields(self):
        ''' Form must have 10 fields '''
        form = PersonForm()
        expected = ['first_name', 'last_name', 'email', 'address',
                    'complement', 'district', 'city', 'uf', 'cep', 'blocked']
        self.assertSequenceEqual(expected, list(form.fields))

    def assertFormErrorMessage(self, form, field, msg):
        errors = form.errors
        errors_list = errors[field]
        self.assertListEqual([msg], errors_list)

    def make_validated_form(self, **kwargs):
        data = dict(**PERSON_DICT, **kwargs)
        form = PersonForm(data)
        form.is_valid()
        return form
